# This migration comes from sessions (originally 20200217121845)
class CreateSessionsManagers < ActiveRecord::Migration[5.2]
  def change
    create_table :sessions_managers do |t|
      t.belongs_to :user
      t.belongs_to :session
      t.timestamps
    end
  end
end
