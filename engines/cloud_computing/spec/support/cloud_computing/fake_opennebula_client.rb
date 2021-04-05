module CloudComputing
  class FakeOpennebulaClient

    attr_reader :logger, :vms

    def self.vms
      @vms ||= []
    end

    def self.logger
      @logger ||= []
    end

    def vms
      self.class.vms
    end

    def logger
      self.class.logger
    end

    def initialize(_connection_params)
      # @server = XMLRPC::Client.new3(connection_params.except(:user, :password))
      # @session_string = connection_params.slice(:user, :password).values.join(':')

    end

    def to_xml(hash)
      key = hash.keys.first
      value = hash[key]
      value.to_xml(root: key)
    end

    def xmlrpc_send(*args)
      pp args
      logger << args
    end

    def template_list
      xmlrpc_send('templatepool.info', -3, -1, -1)
    end

    def delete_template(template_id)
      xmlrpc_send('template.delete', template_id, true)
    end

    def template_info(template_id)
      xmlrpc_send('template.info', template_id, false, false)
      [true, to_xml(
        'VMTEMPLATE' => {
          'TEMPLATE' => {}
        }
      )]
    end

    def vm_action(vm_id, action)
      xmlrpc_send('vm.action', action, vm_id)
      result = vms.detect { |vm| vm['VM']['ID'].to_s == vm_id.to_s }
      if result
        if action == 'poweroff-hard'
          if result['VM']['STATE'] == '3' && result['VM']['LCM_STATE'] == '3'
            result['VM']['STATE'] = '8'
            result['VM']['LCM_STATE'] = '0'
            [true, vm_id]
          else
            [false, 'wrong state', 2, vm_id]
          end
        elsif action == 'resume'
          if result['VM']['STATE'] == '8' && result['VM']['LCM_STATE'] == '0'
            result['VM']['STATE'] = '3'
            result['VM']['LCM_STATE'] = '3'
            [true, vm_id]
          else
            [false, 'wrong state', 2, vm_id]
          end
        end
        [false, 'I can not do this action ', 3, vm_id]

      else
        [false, 'no such vm', 1, vm_id]
      end
    end

    def vm_attachnic(vm_id, nic_id)
      str = "NIC = [ NETWORK_ID = #{nic_id} ]"
      xmlrpc_send('vm.attachnic', vm_id, str)
      result = vms.detect { |vm| vm['VM']['ID'].to_s == vm_id.to_s }
      if result
        unless result['VM']['TEMPLATE']['NIC'] .is_a? Array
          result['VM']['TEMPLATE']['NIC'] = [result['VM']['TEMPLATE']['NIC']]
        end
        result['VM']['TEMPLATE']['NIC'] << {
          'NETWORK_ID' => nic_id.to_s,
          'NIC_ID' => '2',
          'IP' => "190.160.0.#{result['VM']['ID']}"
        }
        [true, vm_id]
      else
        [false, 'no such vm', 1, vm_id]
      end
    end

    def vm_detachnic(vm_id, nic_id)
      xmlrpc_send('vm.detachnic', vm_id, nic_id.to_i)
      result = vms.detect { |vm| vm['VM']['ID'].to_s == vm_id.to_s }
      if result
        unless result['VM']['TEMPLATE']['NIC'] .is_a? Array
          result['VM']['TEMPLATE']['NIC'] = [result['VM']['TEMPLATE']['NIC']]
        end

        result['VM']['TEMPLATE']['NIC'].reject! do |n|
          n['NIC_ID'] == nic_id.to_s
        end
        [true, vm_id]
      else
        [false, 'no such vm', 1, vm_id]
      end
    end

    def vm_updateconf(vm_id, string)
      xmlrpc_send('vm.updateconf', vm_id, string)
    end


    def vm_reinstall(vm_id)
      xmlrpc_send('vm.recover', vm_id, 4)
    end


    def terminate_vm(vm_id)
      xmlrpc_send('vm.action', 'terminate-hard', vm_id)
    end

    def update_context_for_template(template_id, context_hash)
      values = context_hash.map { |key, value| "#{key}=\"#{value}\"" }.join(',')
      context_string = "CONTEXT=[#{values}]"
      xmlrpc_send('template.update', template_id, context_string, 1)
    end

    def instantiate_vm(template_id, vm_name, value_string)
      xmlrpc_send('template.instantiate', template_id, vm_name, false,
                  value_string, true)
      id = vms.last ? vms.last['VM']['ID'] : 0
      id = id.to_i + 1
      context_hash = value_string.partition('CONTEXT=[').last.split("\n")
                                 .map do |splited|
        splited.split('=')
      end.to_h
      context_hash['SSH_PUBLIC_KEY'] = 'SSH KEY IS WRITTEN HERE'
      context_hash['DISK'] = {
        'SIZE' => '128'
      }
      context_hash['NIC'] = {
        'NETWORK_ID' => CloudComputing::CloudAttribute.find_by_key('local_network_id').value,
        'NIC_ID' => '1',
        'IP' => "192.168.0.#{id}"
      }

      context_hash.each do |key, value|
        context_hash[key] = value.tr('"', '') if value.is_a? String
      end


      new_vm = {
        'VM' => {
          'shown_times' => 0,
          'STATE' => '1',
          'LCM_STATE' => '0',
          'ID' => id.to_s,
          'TEMPLATE' => context_hash,
          'NAME' => vm_name
        }
      }
      # new_vm['TEMPLATE'] = {
      #   'SIZE' => '128'
      # }

      # puts new_vm.inspect.red

      vms << new_vm
      pp new_vm
      [true, id]
    end

    def vm_info(vm_id)
      xmlrpc_send('vm.info', vm_id, false)
      result = vms.detect { |vm| vm['VM']['ID'].to_s == vm_id.to_s }
      if result
        result['VM']['shown_times'] += 1
        shown_times = result['VM']['shown_times']
        puts "#{vm_id}: #{shown_times}"
        if shown_times == 3
          result['VM']['STATE'] = '3'
          result['VM']['LCM_STATE'] = '3'
        end
        [true, to_xml(result)]
      else
        [false, 'no such vm', 1, vm_id]
      end
      # [true, ]
    end

    def vm_disk_resize(vm_id, disk_id, size)
      xmlrpc_send('vm.diskresize', vm_id, disk_id, size)
      result = vms.detect { |vm| vm['VM']['ID'].to_s == vm_id.to_s }
      if result
        result['VM']['TEMPLATE']['DISK']['SIZE'] = size
        [true, vm_id]
      else
        [false, 'no such vm', 1, vm_id]
      end
    end

    def vm_resize(vm_id, str)
      xmlrpc_send('vm.resize', vm_id, str, false)
      result = vms.detect { |vm| vm['VM']['ID'].to_s == vm_id.to_s }
      if result
        # result['VM']['TEMPLATE']['DISK']['SIZE'] = size
        [true, vm_id]
      else
        [false, 'no such vm', 1, vm_id]
      end
    end
  end
end
