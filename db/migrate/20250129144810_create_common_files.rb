class CreateCommonFiles < ActiveRecord::Migration[5.2]
  def change
    create_table :common_files do |t|
      t.text :description
      t.string :file
      t.timestamps
    end
  end
end
