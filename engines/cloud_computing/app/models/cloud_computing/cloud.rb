module CloudComputing
  class Cloud < ApplicationRecord
    # enum kind: %i[opennebula http ssh]
    translates :name, :description
    has_many :templates, inverse_of: :cloud
  end
end
