class CreateCloudComputingVirtualMachineActions < ActiveRecord::Migration[5.2]
  def change
    create_table :cloud_computing_virtual_machine_actions do |t|
      t.belongs_to :virtual_machine, index: { name: 'virtual_machine_index' }
      t.string :action
      t.string :name_ru
      t.string :name_en
      t.text :description_ru
      t.text :description_en
      t.text :alert_ru
      t.text :alert_en

      t.timestamps
    end
  end
end
