FactoryBot.define do
  factory :cloud_resource, class: "CloudComputing::Resource" do
    association :template, factory: :cloud_template
    association :resource_kind, factory: :cloud_resource_kind #, template_kind: template.template_kind
    # cloud_resource_kind:cpu, template_kind: template.template_kind)
    to_create { |instance| instance.save(validate: false) }
    value { 1 }

    trait :memory do
      # resource_kind { CloudComputing::ResourceKind.find_by_identity('MEMORY') || create(:cloud_resource_kind, :memory)  }
      min { 1 }
      value { 1.5 }
      max { 2 }
      editable { true }
    end

    trait :cpu do
      # resource_kind { CloudComputing::ResourceKind.find_by_identity('CPU') || create(:cloud_resource_kind, :cpu, template_kind: template.template_kind ) }
      min { 1 }
      value { 2 }
      max { 3 }
      editable { true }
    end

    trait :disk do
      # resource_kind { CloudComputing::ResourceKind.find_by_identity('DISK=>SIZE') || create(:cloud_resource_kind, :disk) }
      value { 2 }
      editable { false }
    end

    trait :internet do
      value { 1 }
      editable { true }
    end

    trait :imaginary do
      # resource_kind { CloudComputing::ResourceKind.find_by_name('Imaginary') || create(:cloud_resource_kind, :imaginary) }
      value { 1000 }
      editable { false }
    end

  end
end
