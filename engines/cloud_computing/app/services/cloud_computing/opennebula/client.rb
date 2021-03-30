module CloudComputing
  module Opennebula
    class Client
      #Hash.from_xml(CloudComputing::OpennebulaClient.vm_info(498)[1])['VM']['TEMPLATE']['NIC']

      def initialize(connection_params)
        @server = XMLRPC::Client.new3(connection_params.except(:user, :password))
        @session_string = connection_params.slice(:user, :password).values.join(':')
      end

      def xmlrpc_send(*args)
        @server.call('one.' + args.first, @session_string, *args.slice(1..-1))
      end

      def template_list
        xmlrpc_send('templatepool.info', -3, -1, -1)
      end

      def delete_template(template_id)
        xmlrpc_send('template.delete', template_id, true)
      end

      def template_info(template_id)
        xmlrpc_send('template.info', template_id, false, false)
      end


      def vm_action(vm_id, state)
        xmlrpc_send('vm.action', state, vm_id)
      end

      def vm_attachnic(vm_id, nic_id)
        str = "NIC = [ NETWORK_ID = #{nic_id} ]"
        xmlrpc_send('vm.attachnic', vm_id, str)
      end

      def vm_detachnic(vm_id, nic_id)
        xmlrpc_send('vm.detachnic', vm_id, nic_id.to_i)
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
      end

      def vm_info(vm_id)
        xmlrpc_send('vm.info', vm_id, false)
      end

      def vm_disk_resize(vm_id, disk_id, size)
        xmlrpc_send('vm.diskresize', vm_id, disk_id, size)
      end

      def vm_resize(vm_id, str)
        xmlrpc_send('vm.resize', vm_id, str, false)
      end
    end
  end
end
