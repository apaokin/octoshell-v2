class CommonFile < ApplicationRecord
  mount_uploader :file, ::FileUploader
  validates :description, :file, presence: true
end
