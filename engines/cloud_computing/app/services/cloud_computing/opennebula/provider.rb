module CloudComputing
  module Opennebula
    class Provider
      attr_accessor :client


      def self.client_class
        @client_class ||= Client
      end

      def self.connection(connection_params)
        new(connection_params)
      end

      def initialize(connection_params)
        @client = self.class.client_class.new(connection_params)
      end

      def operation(operation, params)
        public_send(operation, params)
      end

      def create_and_update_vms(params, env_params = {})
        r = Operations::CreateAndUpdate.new(client, env_params).execute(params)
        CloudProvider.receive_on_create_and_update_vms(r)
      end

      def finish_access(params, _env_params = {})
        r = Operations::FinishAccess.new(client).execute(params)
        CloudProvider.receive_on_finish_access(r)
      end

      def terminate_access(params, _env_params = {})
        params = params.map { |param| Operations::Param.new(param) }
        params.each do |param|
          next unless param['vm_id']

          vm_id = param['vm_id']
          callback = Callback.new(client, vm_id, State.done)
          results = callback.wait do
            template_id = callback.vm_data['TEMPLATE']['TEMPLATE_ID'].to_i
            ['delete_template'] +
              client.delete_template(template_id)
          end
          next unless results.is_a? Array

          param.add_result_pos(nil, *results)
        end
        CloudProvider.receive_on_terminate_access(params
          .map(&:back_for_octoshell))
      end

      def show(params, env_params = {})
        params = params.map { |param| Operations::Param.new(param) }
        params.each do |param|
          next unless param['vm_id']

          Operations::Show.new(param, client).assign_ips_and_state(env_params)
        end
        CloudProvider.receive_on_show(params.map(&:back_for_octoshell))
      end

      def execute_action(params, env_params = {})
        r = Operations::ExecuteAction.new(client, env_params).execute(params)
        CloudProvider.receive_on_execute_action(r)
      end




      def template_list(hash)
        request_results = client.template_list
        return { success: false, data: results[1..-1] } unless request_results[0]

        results = []
        data = Hash.from_xml(request_results[1])['VMTEMPLATE_POOL']['VMTEMPLATE']
        data.each do |template|
          next if template['TEMPLATE']['OCTOSHELL_BOUND_TO_TEMPLATE']
          next if template['TEMPLATE']['VROUTER'] == 'yes'

          results << {
            'identity' => template['ID'],
            'NAME' => template['NAME'],
            'CPU' => template['TEMPLATE']['CPU'],
            'MEMORY' => template['TEMPLATE']['MEMORY'].to_f / 1024
          }.merge(hash)
        end
        CloudProvider.receive_on_template_list('success' => true,
                                               'data' => results)
      end



    end
  end
end
