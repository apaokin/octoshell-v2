module CloudComputing
  module Opennebula
    module Operations
      class CreateAndUpdate
        attr_reader :client, :internet_network_id, :local_network_id

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
          numeric_types + boolean_types + ['SET_HOSTNAME']
        end

        def initialize(client, env_params)
          @client = client
          @env_params = env_params
          @internet_network_id = env_params['internet_network_id']
          @local_network_id = env_params['local_network_id']
        end


        def vm_list(param)
          results = client.vm_list
          unless results[0]
            param.add_result_pos(nil, 'vm_list', *results[0..2])
            return false
          end

          Hash.from_xml(results[1])['VM_POOL']['VM']

          # .first['USER_TEMPLATE']['OCTOSHELL_BOUND_TO_TEMPLATE']

        end

        def exists?(vm_list, item_id)
          vm_list.any? do |vm|
            vm['USER_TEMPLATE']['OCTOSHELL_ITEM_ID'] == item_id.to_s
          end
        end

        def create(param)
          return if param['vm_id']

          template_id = param['template_id']
          template_info_results = client.template_info(template_id)
          unless template_info_results[0]
            param.add_result_pos(nil, 'template_info', *template_info_results[0..2])
            return
          end
          access_id = param['access_id']
          item_id = param['item_id']
          name = "octo-#{access_id}-#{item_id}"

          hash = {}
          hash['CONTEXT'] = Hash.from_xml(template_info_results[1])['VMTEMPLATE']['TEMPLATE']['CONTEXT'] || {}
          hash['CONTEXT']['SSH_PUBLIC_KEY'] = param['public_keys']
          hash['CONTEXT']['SET_HOSTNAME'] = param.value('SET_HOSTNAME') if param.value('SET_HOSTNAME').present?

          hash['USER'] = 'root'
          hash['OCTOSHELL_BOUND_TO_TEMPLATE'] = 'OCTOSHELL_BOUND_TO_TEMPLATE'
          hash['OCTOSHELL_ITEM_ID'] = item_id.to_s
          value = param.value('MEMORY')
          if value
            hash['MEMORY'] = value.to_i
          end

          value = param.value('CPU')
          if value
            hash['CPU'] = value.to_i
            hash['VCPU'] = value.to_i
          end
          vm_list = vm_list(param)
          return unless vm_list
          return if exists?(vm_list, item_id)

          instantiate_results = client.instantiate_vm(template_id, name, hash)

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

        def callback(vm_id, state, *args, &block)
          callback = Callback.new(client, vm_id, state)
                             .exit_condition(&block)
          callback.wait(*args)
        end

        def logged_callback(param, key, state, *args, &block)
          result = callback(param['vm_id'], state, *args, &block)
          if result.is_a? Array
            param.add_result_pos(key, *result)
          end
        end


        def vm_disk_resize(param)
          vm_id = param['vm_id']
          size = param.value('DISK=>SIZE').to_s
          return unless size

          logged_callback(param, 'DISK=>SIZE', State.running,
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
          callback = Callback.new(client, vm_id, State.alive_states)
          callback.exit_condition do |vm_data|
            nics = vm_data['TEMPLATE']['NIC']
            nics = [nics] if nics.is_a?(Hash)
            internet_nic = nics.detect { |nic| nic['NETWORK_ID'] == internet_network_id }
            internet_nic.nil? == detach_internet
          end
          result = if detach_internet
                     callback.wait do
                       nics = callback.vm_data['TEMPLATE']['NIC']
                       nics = [nics] if nics.is_a?(Hash)
                       internet_nic = nics.detect do |nic|
                         nic['NETWORK_ID'] == internet_network_id
                       end
                       ['vm_detachnic'] +
                         client.vm_detachnic(vm_id, internet_nic['NIC_ID'])
                     end
                   else
                     callback.wait(:vm_attachnic, vm_id, internet_network_id)
                   end

          param.add_result_pos('internet', *result) if result.is_a? Array
        end

        def resize(param)
          vm_id = param['vm_id']
          callback = Callback.new(client, vm_id, State.poweroff)
                             .exit_condition do |vm_data|
            hash = {}
            %w[CPU MEMORY].each do |key|
              next if param.value(key).nil?

              hash[key] = param.value(key) if param.value(key).to_f != vm_data['TEMPLATE'][key].to_f
            end
            hash.empty?
          end
          hash = {}
          result = callback.wait do
            %w[CPU MEMORY].each do |key|
              next if param.value(key).nil?

              hash[key] = param.value(key) if param.value(key).to_f != callback.vm_data['TEMPLATE'][key].to_f
            end
            hash['VCPU'] = hash['CPU'] if hash['CPU']
            ['vm_resize'] +
              client.vm_resize(vm_id, hash)
          end
          return unless result.is_a? Array

          hash.slice('CPU', 'MEMORY').keys.each do |key|
            param.add_result_pos(key, *result)
          end
        end

        def resume(param)
          vm_id = param['vm_id']
          logged_callback(param, nil, State.poweroff,
                          :vm_action, vm_id, 'resume') do |vm_data|
            vm_data['STATE'] == '3' && vm_data['LCM_STATE'] == '3'
          end
        end

        def update_conf(param)
          vm_id = param['vm_id']
          public_keys = param['public_keys']
          host_name = param.value('SET_HOSTNAME')

          callback = Callback.new(client, vm_id, State.alive_states)
          callback.exit_condition do |vm_data|
            context = vm_data['TEMPLATE']['CONTEXT']
            context['SSH_PUBLIC_KEY'].to_s == public_keys.to_s &&
              context['SET_HOSTNAME'].to_s == host_name.to_s
          end

          changed = []
          result = callback.wait do
            context = callback.vm_data['TEMPLATE']['CONTEXT']

            if public_keys.to_s != context['SSH_PUBLIC_KEY'].to_s
              context['SSH_PUBLIC_KEY'] = public_keys
              changed << nil
            end

            if host_name.to_s != context['SET_HOSTNAME'].to_s
              context['SET_HOSTNAME'] = host_name
              changed << 'SET_HOSTNAME'
            end
            ['vm_updateconf'] +
              client.vm_updateconf(vm_id, context)
           end

          changed.each do |key|
            param.add_result_pos(key, *result) if result.is_a? Array
          end

        end

        def update(param)

          vm_id = param['vm_id']
          return unless vm_id

          update_conf(param)
          vm_disk_resize(param)
          attach_or_detach_internet(param)
          resize(param)
          resume(param)
          Show.new(param, client).assign_ips_and_state(@env_params)
        end

        def execute(params)
          @params = params.map { |param| Operations::Param.new(param) }
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
