class OctoSetting < ApplicationRecord
  KINDS = %i[policy full_organization_name].freeze
  def self.human_kinds
    KINDS.map do |kind|
      [kind, human_attribute_name(kind)]
    end
  end
end
