module CloudComputing
  module Opennebula
    module Operations
      require 'main_spec_helper'
      describe CreateAndUpdate do
        before(:each) do
          url = URI((Rails.application.secrets.cloud_computing || {})[:uri])
          connection_params = {
            user: url.user,
            password: url.password,
            host: url.host,
            port: url.port,
            path: url.path.empty? ? nil : url.request_uri,
            use_ssl: url.scheme == 'https'
          }.stringify_keys
          @client = CloudComputing::Opennebula::Client.new(connection_params)
          @create = CreateAndUpdate.new(@client, {})
        end
        after(:each) do
          if @vm_id
            CloudComputing::Opennebula::Operations::FinishAccess.new(@client).execute([{
              'vm_id' => @vm_id
            }])
            callback = Callback.new(@client, @vm_id, State.done)
            callback.wait do
              template_id = callback.vm_data['TEMPLATE']['TEMPLATE_ID'].to_i
              ['delete_template'] +
                @client.delete_template(template_id)
            end
          end
        end

        it 'does not create vm twice' do
          params = {
            "item_id"=>7,
            "access_id"=>7,
            "template_id"=>71,
            "public_keys"=>""
          }
          result = @create.execute([params])
          @vm_id = result.first['vm_id']
          expect(result.first).to include('success' => true)
          expect(@vm_id).to be_truthy

          result = @create.execute([params])
          expect(result.first['success']).to be_nil

        end
      end






    end
  end
end
