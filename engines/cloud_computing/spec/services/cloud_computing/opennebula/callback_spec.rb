module CloudComputing
  module Opennebula
    require 'main_spec_helper'
    describe Callback do
      context 'disk_resize' do
        it 'resizes disk successfully' do
          value = '2048'
          client = Class.new do
            def self.vm_info(_template_id)
              [true, {
                'STATE' => '3',
                'LCM_STATE' => '3',
                  'TEMPLATE' => {
                    'DISK' => {
                      'SIZE' => '2000'
                    }
                  }
              }.to_xml(root: 'VM')]
            end

            def self.vm_disk_resize(_identity, _0, _value)
              [true, 'message', 'code']
            end
          end
          callback = Callback.new(client, 1, 'ACTIVE', 'RUNNING').exit_condition do |vm_data|
            vm_data['TEMPLATE']['DISK']['SIZE'] == value
          end
          expect(callback.wait do
            client.vm_disk_resize(1, 0, value)
          end[0]).to eq true
        end

      it 'resizes disk successfully when transition to required state is needed' do
        value = '2048'
        client = Class.new do
          def self.vm_info(_template_id)
            @state ||= '8'
            @lcm_state ||= '0'
            [true, {
              'STATE' => @state,
              'LCM_STATE' => @lcm_state,
                'TEMPLATE' => {
                  'DISK' => {
                    'SIZE' => '2000'
                  }
                }
            }.to_xml(root: 'VM')]
          end

          def self.vm_disk_resize(_identity, _0, _value)
            [true, 'message', 'code']
          end

          def self.vm_action(_identity, _action)
            @state = '3'
            @lcm_state = '3'
          end
        end
        callback = Callback.new(client, 1, 'ACTIVE', 'RUNNING').exit_condition do |vm_data|
          vm_data['TEMPLATE']['DISK']['SIZE'] == value
        end
        expect(callback.wait do
          client.vm_disk_resize(1, 0, value)
        end[0]).to eq true
      end



      end
    end
  end
end
