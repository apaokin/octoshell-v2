module CloudComputing
  module Opennebula
    module Operations
      class FinishAccess
        attr_reader :client

        def initialize(client)
          @client = client
        end

        def terminate_vm(param)
          vm_id = param['vm_id']
          callback = Callback.new(client, vm_id, State.for_termination)
          callback.exit_condition do |vm_data|
            State.find_state(vm_data['STATE'], vm_data['LCM_STATE']) == State.done
          end
          result = callback.wait(:terminate_vm, vm_id)
          if result.is_a? Array
            param.add_result_pos(nil, *result)
            result[1]
          else
            param.add_result(success: result)
            result
          end
        end



        def execute(params)
          @params = params.map { |param| Param.new(param) }
          @params.each do |param|
            next unless param['vm_id']

            if terminate_vm(param)
              param['internet_network_id'] = false
              param['local_network_id'] = false
            end
            Show.new(param, client).assign_state
          end

          @params.map(&:back_for_octoshell)
        end

      end
    end
  end
end
