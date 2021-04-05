module CloudComputing
  module Opennebula
    module Operations
      class CreateAndUpdate
        attr_reader :client
        attr_accessor :env_params

        def self.gb_param_types
          %w[MEMORY DISK=>SIZE]
        end

        def self.numeric_types
          gb_param_types + ['CPU']
        end

        def self.boolean_types
          ['internet']
        end

        def self.all_param_types
          numeric_types + boolean_types
        end


        def internet_network_id
          @internet_network_id
        end

        def local_network_id
          @local_network_id
        end

        def initialize(client, env_params)
          @client = client
          @internet_network_id = env_params['internet_network_id']
          @local_network_id = env_params['local_network_id']
        end

        def to_value_string(hash, delim)
          hash.map do |key, value|
            if value.is_a? Hash
              "#{key}=[#{to_value_string(value, ',')}]"
            else
              "#{key}=\"#{value}\""
            end
          end.join(delim)
        end

        def create(param)
          return if param['vm_id']

          template_id = param['template_id']
          template_info_results = client.template_info(template_id)
          unless template_info_results[0]
            param.add_result_pos(nil, 'template_info', *template_info_results[0..2])
            return
          end
          hash = {}
          hash['CONTEXT'] = Hash.from_xml(template_info_results[1])['VMTEMPLATE']['TEMPLATE']['CONTEXT'] || {}
          hash['CONTEXT']['SSH_PUBLIC_KEY'] = param['public_keys']
          hash['USER'] = 'root'
          hash['OCTOSHELL_BOUND_TO_TEMPLATE'] = 'OCTOSHELL_BOUND_TO_TEMPLATE'

          value = param.value('MEMORY')
          if value
            hash['MEMORY'] = value.to_i
          end

          value = param.value('CPU')
          if value
            hash['CPU'] = value.to_i
            hash['VCPU'] = value.to_i
          end
          value_string = to_value_string(hash, "\n")
          access_id = param['access_id']
          item_id = param['item_id']
          name = "octo-#{access_id}-#{item_id}"
          instantiate_results = client.instantiate_vm(template_id, name, value_string)

          if instantiate_results[0]
            param['vm_id'] = instantiate_results[1]
            param.add_result(success: true)
            param.add_result(key: 'CPU', success: true)
            param.add_result(key: 'MEMORY', success: true)
          else
            param.add_result_pos(nil, 'instantiate_vm', *instantiate_results[0..2])
            param.add_result(key: 'CPU', success: false)
            param.add_result(key: 'MEMORY', success: false)
          end
        end

        def callback(vm_id, state, lcm_state, *args, &block)
          callback = Callback.new(client, vm_id, state, lcm_state)
                             .exit_condition(&block)
          callback.wait(*args)
        end

        def logged_callback(param, key, state, lcm_state, *args, &block)
          result = callback(param['vm_id'], state, lcm_state, *args, &block)
          if result.is_a? Array
            param.add_result_pos(key, *result)
          end
        end


        def vm_disk_resize(param)
          vm_id = param['vm_id']
          size = param.value('DISK=>SIZE')
          return unless size

          logged_callback(param, 'DISK=>SIZE', 'ACTIVE', 'RUNNING',
                          :vm_disk_resize, vm_id,
                          0, size) do |vm_data|
            vm_data['TEMPLATE']['DISK']['SIZE'] == size
          end
        end

        def attach_or_detach_internet(param)
          vm_id = param['vm_id']
          internet_value = param.value('internet')
          return if internet_value.nil?

          detach_internet = ![1, true, '1'].include?(internet_value)
          internet_nic = nil
          callback = Callback.new(client, vm_id, 'ACTIVE', 'RUNNING')
                             .exit_condition do |vm_data|
            nics = vm_data['TEMPLATE']['NIC']
            nics = [nics] if nics.is_a?(Hash)
            internet_nic = nics.detect { |nic| nic['NETWORK_ID'] == internet_network_id }
            internet_nic.nil? == detach_internet
          end

          result = if detach_internet
                     callback.wait(:vm_detachnic, vm_id, internet_nic['NIC_ID'])
                   else
                     callback.wait(:vm_attachnic, vm_id, internet_network_id)
                   end

          param.add_result_pos('internet', *result) if result.is_a? Array
        end

        def resize(param)
          vm_id = param['vm_id']
          hash = {}
          callback = Callback.new(client, vm_id, 'POWEROFF', 'LCM_INIT')
                             .exit_condition do |vm_data|
            %w[CPU MEMORY].each do |key|
              next if param.value(key).nil?

              hash[key] = param.value(key) if param.value(key).to_f != vm_data['TEMPLATE'][key].to_f
            end
            hash.empty?
          end

          str = hash.merge('VCPU' => hash['CPU'])
                    .map { |key, r| "#{key}=\"#{r}\"" }.join("\n")
          result = callback.wait(:vm_resize, vm_id, str)
          return unless result.is_a? Array

          hash.keys.each do |key|
            param.add_result_pos(key, *result)
          end
        end

        def resume(param)
          vm_id = param['vm_id']

          logged_callback(param, nil, 'POWEROFF', 'LCM_INIT',
                          :vm_action, vm_id, 'resume') do |vm_data|
            vm_data['STATE'] == 3 && vm_data['LCM_STATE'] == 3
          end
        end

        def assign_ips(param)

          callback = Callback.new(client, param['vm_id'], 'ACTIVE', 'RUNNING')
          result = callback.wait

          if result.is_a? Array
            param.add_result_pos(nil, *result)
            return unless result[1]
          end


          nics = callback.vm_data['TEMPLATE']['NIC']
          nics = [nics] if nics.is_a?(Hash)
          %w[local_network_id internet_network_id].each do |type|
            needed_nic = nics.detect { |nic| nic['NETWORK_ID'] == send(type) }
            param[type] ||= needed_nic['IP'] if needed_nic
          end

        end


        def update(param)

          vm_id = param['vm_id']
          return unless vm_id

          vm_disk_resize(param)
          attach_or_detach_internet(param)
          resize(param)
          # resume(param)
          assign_ips(param)
        end

        def execute(params)
          @params = params.map { |param| Param.new(param) }
          @params.each do |param|
            create(param)
          end

          @params.each do |param|
            update(param)
          end

          @params.map(&:back_for_octoshell)
        end
      end
    end
  end
end
