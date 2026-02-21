class AddAccessFromToSessions < ActiveRecord::Migration[7.2]
  def change
    add_column :sessions_sessions, :access_from, :datetime
  end
end
