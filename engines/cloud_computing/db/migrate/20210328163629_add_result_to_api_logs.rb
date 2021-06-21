class AddResultToApiLogs < ActiveRecord::Migration[5.2]
  def change
    add_column :cloud_computing_api_logs, :result, :boolean
  end
end
