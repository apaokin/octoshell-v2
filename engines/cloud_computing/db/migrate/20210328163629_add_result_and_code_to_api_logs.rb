class AddResultAndCodeToApiLogs < ActiveRecord::Migration[5.2]
  def change
    add_column :cloud_computing_api_logs, :success, :boolean
    add_column :cloud_computing_api_logs, :code, :string

  end
end
