class AddSearchToSupportFields < ActiveRecord::Migration[5.2]
  def change
    add_column :support_fields, :search, :boolean, default: false
  end
end
