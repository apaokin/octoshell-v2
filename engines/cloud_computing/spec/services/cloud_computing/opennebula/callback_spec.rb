module CloudComputing
  module Opennebula
    require 'main_spec_helper'
    describe Callback do
      context 'disk_resize' do
        it 'resizes disk successfully' do
          value = '2048'
          client = Class.new do
            def self.vm_info(_id)
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

            def self.vm_disk_resize(_identity, _disk, _value)
              [true, 'message', 'ok']
            end
          end
          callback = Callback.new(client, 1, 'ACTIVE', 'RUNNING').exit_condition do |vm_data|
            vm_data['TEMPLATE']['DISK']['SIZE'] == value
          end
          expect(callback.wait(:vm_disk_resize, 1, 0, value)).to eq(
            ['vm_disk_resize', true, 'message', 'ok'] )
        end

        it 'resizes disk successfully when transition to required state is needed' do
          value = '2048'
          client = Class.new do
            def self.vm_action_executed
              @vm_action_executed
            end

            def self.vm_info(_id)
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

            def self.vm_disk_resize(_identity, _arg, _value)
              [true, 'message', 'ok']
            end

            def self.vm_action(_identity, _action)
              @vm_action_executed = true
              @state = '3'
              @lcm_state = '3'
            end
          end
          callback = Callback.new(client, 1, 'ACTIVE', 'RUNNING').exit_condition do |vm_data|
            vm_data['TEMPLATE']['DISK']['SIZE'] == value
          end
          expect(callback.wait(:vm_disk_resize, 1, 0, value)).to eq ['vm_disk_resize',
                true, 'message', 'ok']

          expect(client.vm_action_executed).to eq true

        end


        it 'returns error in vm_info' do

          client = Class.new do
            def self.vm_info(id)
              [false, 'error_message', 'error', id]
            end
          end
          callback = Callback.new(client, 1, 'ACTIVE', 'RUNNING').exit_condition do |vm_data|
            raise_error
          end
          expect(callback.wait(:vm_disk_resize, 1, 0, 'value')).to eq(
            ['vm_info', false, 'error_message', 'error', id])
        end



        it 'returns error because of incorrect state' do
          client = Class.new do
            def self.vm_info(_id)
              @state ||= '6'
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

          end
          callback = Callback.new(client, 1, 'ACTIVE', 'RUNNING').exit_condition do |vm_data|
            vm_data['TEMPLATE']['DISK']['SIZE'] == '2005'
          end

          expect(callback.wait(:vm_disk_resize, 1, 0, 'value')).to eq(
            ['error_state', false, %w[DONE LCM_INIT], nil])
        end

      end
    end
  end
end
