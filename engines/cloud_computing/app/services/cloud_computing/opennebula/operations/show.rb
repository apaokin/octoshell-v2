module CloudComputing
  module Opennebula
    module Operations
      class Show

        # attr_reader :param, :client
        #
        def initialize(param, client)
          @param = param
          @client = client
          # @env_params = env_params
        end

        def assign_ips_and_state(env_params)
          assign_ips(env_params)
          assign_state
        end


        def assign_ips(env_params)
          callback = Callback.new(@client, @param['vm_id'], State.show_states)
          result = callback.wait
          if result.is_a? Array
            @param.add_result_pos(nil, *result)
            return unless result[1]
          end
          @vm_data = callback.vm_data
          nics = @vm_data['TEMPLATE']['NIC'] || []
          nics = [nics] if nics.is_a?(Hash)
          %w[local_network_id internet_network_id].each do |type|
            needed_nic = nics.detect { |nic| nic['NETWORK_ID'] == env_params[type] }
            if needed_nic
              @param[type] = needed_nic['IP']
            else
              @param[type] = false
            end
          end
        end

        def assign_state
          unless @vm_data
            results = @client.vm_info(@param['vm_id'])
            unless results[0]
              @param.add_result_pos(nil, *results)
              return
            end
            @vm_data = Hash.from_xml(results[1])['VM']
          end
          state = State.find_state(@vm_data['STATE'], @vm_data['LCM_STATE'])
          return unless state

          @param['state'] = state.state
          @param['lcm_state'] = state.lcm_state
          @param['human_state_en'] = state.human_state
          @param['success'] = true if @param['success'].nil?
          @param['actions'] = state.possible_actions.map do |action|
            { 'name_en' => action, 'action' => action }
          end
        end


      end
    end
  end
end
