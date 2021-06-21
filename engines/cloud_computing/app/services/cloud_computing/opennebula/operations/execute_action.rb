module CloudComputing
  module Opennebula
    module Operations
      class ExecuteAction
        attr_reader :client

        def initialize(client, env_params)
          @client = client
          @env_params = env_params
        end

        def check_state_and_execute(param)
          vm_id = param['vm_id']
          return unless vm_id

          callback = Callback.new(client, vm_id, State.alive_states)
          result = callback.wait do
            execute_action(param, callback.state)
          end

          if result.is_a? Array
            param.add_result_pos(nil, *result)
            result[1]
          else
            param.add_result(success: result)
            result
          end
        end

        def execute_action(param, state)
          action = param['action']
          vm_id = param['vm_id']
          unless state.possible_actions.include?(action)
            param.add_result_pos(nil, action, false,
              "There is no #{action} action for state \"#{state.short}\" ",
              nil)
            return
          end
          results = if action == 'reinstall'
                      client.vm_reinstall(vm_id)
                    else
                      client.vm_action(vm_id, action)
                    end
          param.add_result_pos(nil, action, *results)
        end

        def execute(params)
          @params = params.map { |param| Param.new(param) }
          @params.each do |param|
            next unless param['vm_id']

            check_state_and_execute(param)
            Show.new(param, client).assign_ips_and_state(@env_params)
          end
          @params.map(&:back_for_octoshell)
        end

      end
    end
  end
end
