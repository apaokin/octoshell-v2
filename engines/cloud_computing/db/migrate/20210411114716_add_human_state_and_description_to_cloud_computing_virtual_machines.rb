class AddHumanStateAndDescriptionToCloudComputingVirtualMachines < ActiveRecord::Migration[5.2]
  def change
    add_column :cloud_computing_virtual_machines, :human_state_ru, :string
    add_column :cloud_computing_virtual_machines, :human_state_en, :string
    add_column :cloud_computing_virtual_machines, :description_ru, :text
    add_column :cloud_computing_virtual_machines, :description_en, :text
    add_column :cloud_computing_virtual_machines, :transition_hint_ru, :text
    add_column :cloud_computing_virtual_machines, :transition_hint_en, :text


  end
end
