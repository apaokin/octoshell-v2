class CreateCloudComputingClouds < ActiveRecord::Migration[5.2]
  def change
    create_table :cloud_computing_clouds do |t|
      t.string :kind
      t.string :name_en
      t.string :name_ru
      t.text :description_en
      t.text :description_ru

      t.text :remote_host
      t.text :remote_private_key
      t.integer :remote_port
      t.string :remote_path
      t.string :remote_user
      t.text :remote_password
      t.text :remote_command
      t.string :remote_proxy_host
      t.integer :remote_proxy_port
      t.boolean :remote_use_ssl

      t.text :octo_password
      t.timestamps
    end
  end
end
