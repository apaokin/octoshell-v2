FactoryBot.define do
  factory :cloud_template_kind, class: "CloudComputing::TemplateKind" do
    sequence(:name) { |n| "item_kind #{n}" }
    sequence(:description) { |n| "The kind #{n} suits ur needs" }

    factory :cloud_vm_template_kind do
      cloud_class { CloudComputing::VirtualMachine }
      sequence(:name) { |n| "Virtual machine kind #{n}" }

      resource_kinds do
        %i[memory cpu disk internet imaginary hostname].map do |trait|
          create(:cloud_resource_kind, trait)
        end
      end
    end

  end
end
