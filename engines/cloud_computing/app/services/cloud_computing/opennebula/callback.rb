module CloudComputing
  module Opennebula
    class Callback
      attr_reader :vm_data, :state

      def self.sleep_seconds
        @sleep_seconds ||= 10
      end

      def self.on(state, lcm_state)
        self.class.new(on: [state, lcm_state])
      end

      def initialize(client, identity, states)
        @client = client
        @identity = identity
        states = [states] if states.is_a?(State)
        @states = states.map do |state|
          if state.is_a?(State)
            state
          elsif state.is_a?(Array)
            State.detect do |cur_state|
              cur_state.state == state[0] && cur_state.lcm_state == state[1]
            end
          end
        end
      end

      def exit_condition(&block)
        @exit_condition = block
        self
      end

      def vm_info
        results = @client.vm_info(@identity)
        return results unless results[0]

        @vm_data = Hash.from_xml(results[1])['VM']
        results
      end

      def check_state
        @state = State.find_state(@vm_data['STATE'], @vm_data['LCM_STATE'])
        return :done if @states.include?(@state)

        if %w[CLONING_FAILURE DONE].include?(@state.state) || @state.fail_alias? ||
           @state.unkn_alias?
          return :error
        end

        @state.change_state_if_possible(client: @client,
                                        identity: @identity,
                                        states: @states)
        :wait
      end

      def wait(*args)
        loop do
          vm_info_results = vm_info
          return(['vm_info'] + vm_info_results) unless vm_info_results[0]

          if @exit_condition
            return true if @exit_condition.call(@vm_data)
          end
          state = check_state
          if state == :error
            return(['error_state', false,
                    [@state.state, @state.lcm_state], nil])
          end
          break if state == :done

          sleep(self.class.sleep_seconds)
        end
        return(yield) if block_given?

        return ([args[0].to_s] + @client.send(*args)) if args.any?

        nil
      end
    end
  end
end
