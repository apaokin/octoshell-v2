class CreateOctoSettings < ActiveRecord::Migration[5.2]
  def change
    create_table :octo_settings do |t|
      t.string :key
      t.text :value_ru
      t.text :value_en
      t.string :kind
      t.boolean :active
      t.timestamps
    end
  end
end
