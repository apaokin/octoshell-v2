class CreateCloudComputingResources < ActiveRecord::Migration[5.2]
  def change
    create_table :cloud_computing_resources do |t|
      t.belongs_to :resource_kind
      t.belongs_to :item
      t.integer :value
      t.boolean :new_requests

      t.timestamps
    end
  end
end
