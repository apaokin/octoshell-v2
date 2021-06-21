module CloudComputing
  class Cloud < ApplicationRecord
    # enum kind: %i[opennebula http ssh]
    translates :name, :description
    has_many :templates, inverse_of: :cloud
    has_many :cloud_attributes, inverse_of: :cloud
    accepts_nested_attributes_for :cloud_attributes
    validates :name, :kind, presence: true

    def self.kinds
      CloudProvider.kinds.keys
    end

  end
end
