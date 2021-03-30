module CloudComputing
  module Opennebula
    class Callback
      SLEEP_SECONDS = 10

      attr_reader :vm_data

      def self.on(state, lcm_state)
        self.class.new(on: [state, lcm_state])
      end


      def internet_network_id
        settings_hash = Rails.application.secrets.cloud_computing || {}
        settings_hash[:internet_network_id]&.to_s
      end

      def inner_network_id
        settings_hash = Rails.application.secrets.cloud_computing || {}
        settings_hash[:inner_network_id]&.to_s
      end

      def initialize(client, identity, required_state, required_lcm_state)
        @client = client
        @identity = identity
        @required_state = required_state
        @required_lcm_state = required_lcm_state
      end

      def exit_condition(&block)
        @exit_condition = block
        self
      end

      def vm_info
        results = @client.vm_info(@identity)
        raise "Error getting vm_info for  #{@identity}" unless results[0]

        @vm_data = Hash.from_xml(results[1])['VM']
      end

      def assign_inner_ip
        nics = @vm_data['TEMPLATE']['NIC']
        if nics.is_a?(Hash)
          nics = [nics]
        end

        if @vm.inner_address.blank?
          inner_nic = nics.detect { |nic| nic['NETWORK_ID'] == inner_network_id }
          if inner_nic
            ip = inner_nic['IP']
            @vm.update!(inner_address: ip)
          end
        end
      end


      def check_state
        state = State.find_state(@vm_data['STATE'], @vm_data['LCM_STATE'])

        if state.equal_to_states?(@required_state, @required_lcm_state)
          return :done
        end

        if %w[CLONING_FAILURE].include?(state.state) || state.fail_alias?
          return :error
        end

        state.change_state_if_possible(client: @client,
                                       identity: @identity,
                                       required_state: @required_state,
                                       required_lcm_state: @required_lcm_state)
        :wait
      end

      # def terminate_vm
      #   result, *arr = OpennebulaClient.terminate_vm(@vm.identity)
      #   return 'terminate_vm_error', arr unless result
      # end

      # def poweroff_hard
      #   change_state('poweroff-hard', 'change state before resize')
      # end
      #
      # def run_if_not
      #   change_state('resume', 'run before any actions')
      # end
      #
      # def resume
      #   change_state('resume', 'change state after resize')
      #   @vm.update!(state_from_code: '3', lcm_state_from_code: '3',
      #               last_info: DateTime.now)
      # end

      # def change_state(state, action)
      #   results = OpennebulaClient.vm_action(@vm.identity, state)
      #   @vm.create_log!(results: results, action: action)
      # end

      # def assign_internet_ip
      #   nics = @vm_data['TEMPLATE']['NIC']
      #   if nics.is_a?(Hash)
      #     nics = [nics]
      #   end
      #   internet_nic = nics.detect { |nic| nic['NETWORK_ID'] == internet_network_id }
      #   ip = internet_nic['IP']
      #   @vm.update!(internet_address: ip)
      # end

      def wait
        loop do
          vm_info
          if @exit_condition
            return true if @exit_condition.call(@vm_data)
          end
          state = check_state
          return :error if state == :error
          break if state == :done

          sleep(SLEEP_SECONDS)
        end
        yield if block_given?
      end
    end
  end
end
