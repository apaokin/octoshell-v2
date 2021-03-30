module CloudComputing
  module Opennebula
    class Provider
      attr_accessor :client


      def self.client_class
        Client
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

      def create_and_update_vms(params)
        Operations::CreateAndUpdate.new(client).execute(params)
      end


      def template_list
        request_results = client.template_list
        return { success: false, data: results[1..-1] } unless request_results[0]

        results = []
        data = Hash.from_xml(request_results[1])['VMTEMPLATE_POOL']['VMTEMPLATE']
        data.each do |template|
          next if template['TEMPLATE']['OCTOSHELL_BOUND_TO_TEMPLATE']
          next if template['TEMPLATE']['VROUTER'] == 'yes'

          results << {
            'NAME' =>  template['NAME'],
            'CPU' => template['TEMPLATE']['CPU'],
            'MEMORY' => template['TEMPLATE']['MEMORY'].to_f / 1024
          }
        end
        { success: true, data: results }
      end



    end
  end
end
