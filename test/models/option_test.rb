# == Schema Information
#
# Table name: options
#
#  id                  :integer          not null, primary key
#  owner_id            :integer
#  owner_type          :string
#  name_ru             :string
#  name_en             :string
#  value_ru            :text
#  value_en            :text
#  category_value_id   :integer
#  options_category_id :integer
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#

require 'test_helper'

class OptionTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
