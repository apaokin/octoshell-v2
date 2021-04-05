class AddBlockedToCloudComputingAccesses < ActiveRecord::Migration[5.2]
  def change
    add_column :cloud_computing_accesses, :blocked, :boolean, default: false
  end
end
