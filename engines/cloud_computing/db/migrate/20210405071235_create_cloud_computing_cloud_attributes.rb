class CreateCloudComputingCloudAttributes < ActiveRecord::Migration[5.2]
  def change
    create_table :cloud_computing_cloud_attributes do |t|
      t.belongs_to :cloud
      t.string :key
      t.string :value
      t.timestamps
    end
  end
end
