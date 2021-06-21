module CloudComputing
  module Opennebula
    class State
      extend Enumerable

      STATES_AFTER_ACTION = {
        'reboot-hard' => %w[ACTIVE RUNNING],
        'reboot' => %w[ACTIVE RUNNING],
        'poweroff' => %w[ACTIVE SHUTDOWN_POWEROFF],
        'poweroff-hard' => %w[ACTIVE SHUTDOWN_POWEROFF],
        'resume' => %w[PENDING LCM_INIT],
        'reinstall' => %w[reinstall CLEANUP_RESUBMIT]
      }.freeze

      ACTIONS = {
        %w[ACTIVE RUNNING] => %w[reboot reboot-hard poweroff poweroff-hard reinstall],
        %w[POWEROFF LCM_INIT] => %w[resume],
        %w[UNDEPLOYED LCM_INIT] => %w[resume],
      }.freeze

      TRANSIT_TO_STATE = {
        %w[ACTIVE RUNNING] =>  { %w[POWEROFF LCM_INIT] => 'resume' },
        %w[POWEROFF LCM_INIT] => { %w[ACTIVE RUNNING] => 'poweroff-hard' }
      }.freeze



      ATTRS = %i[state_id state lcm_state_id lcm_state short_alias meaning].freeze
      attr_reader(*ATTRS)

      def self.load_states
        @vm_states ||= []
        state_id = nil, state = nil
        CSV.read("#{CloudComputing::Engine.root}/config/opennebula_states.csv")[1..-1].each do |a|
          state_id = a[0] if a[0].present?
          state = a[1] if a[1].present?
          @vm_states << new([state_id, state, *a[2..-1]])
        end
      end

      def self.vm_states
        @vm_states || load_states && @vm_states
      end

      def self.find_state(state_id, lcm_state_id)
        vm_states.detect do |state|
          state.state_id == state_id && (lcm_state_id.blank?  ||
              state.lcm_state_id == lcm_state_id)
        end
      end

      def self.each(&block)
        vm_states.each(&block)
      end

      def self.running
        detect do |state|
          state.state == 'ACTIVE' && state.lcm_state == 'RUNNING'
        end
      end

      def self.poweroff
        detect do |state|
          state.state == 'POWEROFF'
        end
      end

      def self.done
        detect do |state|
          state.state == 'DONE'
        end
      end

      def self.alive_states
        select do |state|
          %w[STOPPED SUSPENDED POWEROFF].include?(state.state)
        end + [running]
      end

      def self.show_states
        alive_states + [done]
      end

      def self.for_termination
        show_states
      end


      # def self.poweroff
      #   State.detect do |state|
      #     state.state == 'POWEROFF'
      #   end
      # end



      def initialize(array)
        ATTRS.each_with_index do |a, index|
          val = array[index]
          val = '0' if a == :lcm_state_id && val.blank?
          val = 'LCM_INIT' if a == :lcm_state && val.blank?

          next if val.blank?

          instance_variable_set("@#{a}", val.to_s)
        end
      end

      def possible_actions
        ACTIONS[[state, lcm_state]] || []
      end

      def action_to_reach(states)
        states.each do |c_state|
          state_action = TRANSIT_TO_STATE[[c_state.state, c_state.lcm_state]]
          next unless state_action

          action = state_action[[state, lcm_state]]
          return action if action
        end
        nil
      end

      def equal_to_states?(required_state, required_lcm_state = 'LCM_INIT')
        state == required_state && lcm_state == required_lcm_state
      end

      def ==(other)
        state == other.state && lcm_state == other.lcm_state
      end

      def change_state_if_possible(client:, identity:, states:)
        action = action_to_reach(states)
        return unless action

        change_state(client, action, identity)
      end

      def change_state(client, action, identity)
        return false, 'wrong action' unless possible_actions.include?(action)

        if action == 'reinstall'
          result, *arr = client.vm_reinstall(identity)
        else
          result, *arr = client.vm_action(identity, action)
        end
        [result, arr]
      end

      def fail_alias?
        short_alias == 'fail'
      end

      def unkn_alias?
        short_alias == 'unkn'
      end

      def error_alias?
        fail_alias? || unkn_alias?
      end

      def human_state
        if self == State.running
          'running'
        elsif self == State.poweroff
          'poweroff'
        elsif unkn_alias? || fail_alias?
          'error'
        end
      end

      def short
        "#{state} || #{lcm_state}"
      end






    end
  end
end
