module CloudComputing
  module Opennebula
    require 'main_spec_helper'
      describe Provider do
        before(:each) do
          if ENV['OPENNEBULA_URI']
            begin
              url = URI(ENV['OPENNEBULA_URI'])
            rescue URI::InvalidURIError => e
              raise ArgumentError, e.message, e.backtrace
            end
            connection_params = {
              user: url.user,
              password: url.password,
              host: url.host,
              port: url.port,
              path: url.path.empty? ? nil : url.request_uri,
              use_ssl: url.scheme == 'https'
            }
            @provider = Provider.connection(connection_params)
          else
            @provider = Provider.new({})
          end
        end

        describe '#create_and_update_vms' do
          it 'creates vm successfully' do
            @provider.client = Class.new do
              def self.template_info(_template_id)
                [true, { 'TEMPLATE' => {} }.to_xml(root: 'VMTEMPLATE')]
              end

              def self.instantiate_vm(_template_id, _name, _value_string)
                [true, 1]
              end
            end

            pp results = @provider.create_and_update_vms([
                'item_id' => 10,
                'holder_id' => 20,
                'CPU' => '3',
                'MEMORY' => '0.5',
                'public_keys' => 'RSA'
             ])
             expect(results.first['success']).to eq true
          end

          it 'does not create vm' do
            @provider.client = Class.new do
              def self.template_info(_template_id)
                [true, { 'TEMPLATE' => {} }.to_xml(root: 'VMTEMPLATE')]
              end

              def self.instantiate_vm(_template_id, _name, _value_string)
                [false, 'error', 12]
              end
            end

            pp results = @provider.create_and_update_vms([
                'item_id' => 10,
                'holder_id' => 20,
                'CPU' => '3',
                'MEMORY' => '0.5',
                'public_keys' => 'RSA'
             ])

            expect(results.first['success']).to eq false
            expect(results.first['messages']).to eq [[false, 'error', 12]]
          end
        end

        # describe '#template_list' do
        #   it 'works' do
        #     pp results = @provider.template_list
        #     expect(results[:success]).to eq true
        #   end
        # end
      end
  end
end
