# == Schema Information
#
# Table name: core_surety_scans
#
#  id        :integer          not null, primary key
#  image     :string(255)
#  surety_id :integer
#
# Indexes
#
#  index_core_surety_scans_on_surety_id  (surety_id)
#

module Sureties
  class SuretyScan < ApplicationRecord
    self.table_name = "core_surety_scans"

    belongs_to :surety

    mount_uploader :image, Core::SuretyScanUploader
    validates :image, presence: true
  end
end
