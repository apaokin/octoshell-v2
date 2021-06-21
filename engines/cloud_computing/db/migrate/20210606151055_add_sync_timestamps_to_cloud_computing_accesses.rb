class AddSyncTimestampsToCloudComputingAccesses < ActiveRecord::Migration[5.2]
  def change
    remove_column :cloud_computing_accesses, :blocked, :boolean, default: false
    add_column :cloud_computing_accesses, :started_sync_at, :datetime
    add_column :cloud_computing_accesses, :finished_sync_at, :datetime

  end
end
