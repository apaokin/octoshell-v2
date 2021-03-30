class AddCloudIdToCloudComputingTemplates < ActiveRecord::Migration[5.2]
  def change
    add_reference :cloud_computing_templates, :cloud
  end
end
