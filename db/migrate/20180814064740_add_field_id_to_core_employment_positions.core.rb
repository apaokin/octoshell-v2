# This migration comes from core (originally 20180814064626)
class AddFieldIdToCoreEmploymentPositions < ActiveRecord::Migration
  def change
    add_column :core_employment_positions, :field_id, :integer
  end
end
