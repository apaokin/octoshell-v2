module CloudComputing
  class VirtualMachineAction < ApplicationRecord
    belongs_to :virtual_machine, inverse_of: :virtual_machine_actions
    translates :name, :description, :alert

    def self.human_action(action)
      I18n.t("activerecord.attributes.#{model_name.i18n_key}.actions.#{action}", default: nil)
    end

    def self.human_description(action)
      I18n.t("activerecord.attributes.#{model_name.i18n_key}.actions.#{action}-description", default: nil)
    end

    def self.human_alert(action)
      I18n.t("activerecord.attributes.#{model_name.i18n_key}.actions.#{action}-alert", default: nil)
    end


    def cur_locale(attribute)
      try("#{attribute}_#{I18n.locale}")
    end

    def human_action
      cur_locale(:name) || self.class.human_action(action) || name || action
    end

    def human_description
      cur_locale(:description) || self.class.human_description(action) ||
        description
    end

    def human_alert
      cur_locale(:alert) || self.class.human_alert(action) ||
        alert
    end

  end
end
