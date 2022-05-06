# == Schema Information
#
# Table name: jobstat_digest_string_data
#
#  id         :integer          not null, primary key
#  name       :string
#  time       :datetime
#  value      :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  job_id     :bigint(8)
#
# Indexes
#
#  index_jobstat_digest_string_data_on_job_id  (job_id)
#

module Jobstat
  class DigestStringDatum < ApplicationRecord
    def self.versions_enabled
      false
    end
  end
end
