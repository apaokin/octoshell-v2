# == Schema Information
#
# Table name: category_values
#
#  id                  :integer          not null, primary key
#  options_category_id :integer
#  value_ru            :string
#  value_en            :string
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#

require 'test_helper'

class CategoryValueTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
