module CloudComputing
  module Opennebula
    class State


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

      def action_to_reach(required_state, required_lcm_state)
        states = TRANSIT_TO_STATE[[required_state, required_lcm_state]] || {}
        states[[state, lcm_state]]
      end

      def equal_to_states?(required_state, required_lcm_state = 'LCM_INIT')
        # puts state.inspect
        # puts required_state.inspect
        # puts lcm_state.inspect
        # puts required_lcm_state.inspect
        state == required_state && lcm_state == required_lcm_state
      end

      def change_state_if_possible(client:, identity:,
                                   required_state:, required_lcm_state:)
        action = action_to_reach(required_state, required_lcm_state)
        change_state(client, action, identity)
      end

      def change_state(client, action, identity)
        return false, 'wrong action' unless possible_actions.include?(action)

        if action == 'reinstall'
          result, *arr = client.vm_reinstall(identity)
        else
          result, *arr = client.vm_action(identity, action)
        end
        # if result
        #   states = VirtualMachine::STATES_AFTER_ACTION[action]
        #   self.state = states[0]
        #   self.lcm_state = states[1]
        #   save
        #
        #   states = Array(previous_changes['state'])
        #   lcm_states = Array(previous_changes['lcm_state'])
        #
        #   api_logs.create!(action: "success: #{action}",
        #                    log: "#{states[0]}  #{lcm_states[0]} => #{states[1]} #{lcm_states[1]}")
        #
        # else
        #   api_logs.create!(action: "failure: #{action}",
        #                    log: "#{state} #{lcm_state} | #{arr.inspect}")
        #
        # end
        [result, arr]
      end

      def fail_alias?
        short_alias == 'fail'
      end





    end
  end
end
