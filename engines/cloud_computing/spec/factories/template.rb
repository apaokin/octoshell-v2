FactoryBot.define do
  factory :cloud_template, class: "CloudComputing::Template" do
    association :template_kind, factory: :cloud_template_kind
    association :cloud, factory: :cloud_cloud

    sequence(:name) { |n| "Virtual machine #{n}" }
    sequence(:description_en) { |n| "Virtual machine description #{n}" }
    sequence(:description_ru) { |n| "Virtual machine description #{n}" }
    sequence(:identity) { |n| n }
    new_requests { true }


    factory :cloud_vm_template do
       # CloudComputing::TemplateKind.all.inspect.red
      association :template_kind, factory: :cloud_vm_template_kind

      # template_kind { create(:cloud_vm_template_kind) }
      resources do
        %i[memory cpu disk internet imaginary hostname].each_with_index.map do |trait, index|
          create(:cloud_resource, trait, resource_kind: template_kind.resource_kinds.to_a[index])
        end
      end
    end

  end
end
