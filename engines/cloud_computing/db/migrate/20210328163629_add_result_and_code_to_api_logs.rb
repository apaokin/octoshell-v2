class AddResultAndCodeToApiLogs < ActiveRecord::Migration[5.2]
  def change
    remove_column :cloud_computing_api_logs, :virtual_machine_id, :integer
    add_column :cloud_computing_api_logs, :resource, :string
    add_column :cloud_computing_api_logs, :success, :boolean
    add_column :cloud_computing_api_logs, :code, :string

  end
end
