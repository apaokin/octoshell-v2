require 'csv'
module CloudComputing
  class VirtualMachine < ApplicationRecord
    translates :human_state, :description, :transition_hint
    belongs_to :item, inverse_of: :virtual_machine
    has_many :virtual_machine_actions, inverse_of: :virtual_machine,
                                       autosave: true

    has_many :api_logs, inverse_of: :virtual_machine
    validates :identity, uniqueness: true

    def self.human_state(state)
      I18n.t("activerecord.attributes.#{model_name.i18n_key}.states.#{state}", default: nil)
    end

    def human_last_info
      "#{self.class.human_attribute_name :last_info} #{last_info}"
    end

    def cur_locale(attribute)
      try("#{attribute}_#{I18n.locale}")
    end

    def translated_human_state
      cur_locale(:human_state) || self.class.human_state(human_state) ||
        human_state
    end

    def full_state
      if translated_human_state
        translated_human_state + " (#{state} | #{lcm_state})"
      else
        "#{state} | #{lcm_state}"
      end
    end

    def create_log!(results:, action:)
      api_logs.create!(log: results, action: action, item: item)
    end

    def update_actions(actions)
      virtual_machine_actions.each(&:mark_for_destruction)
      a_names = (CloudComputing::VirtualMachineAction.locale_columns(:name, :description) +
         ['action']).map(&:to_s)
      actions.each do |action|
        attributes = action.slice(*a_names)
        virtual_machine_actions.build(attributes)
      end
    end

  end
end
