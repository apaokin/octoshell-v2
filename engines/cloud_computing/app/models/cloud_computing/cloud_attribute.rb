module CloudComputing
  class CloudAttribute < ApplicationRecord
    belongs_to :cloud, inverse_of: :cloud_attributes
    validates :key, presence: true
  end
end
