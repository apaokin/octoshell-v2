FactoryBot.define do
  factory :cloud_resource_kind, class: "CloudComputing::ResourceKind" do
    association :template_kind, factory: :cloud_template_kind, strategy: :create
    content_type { 'decimal' }
    # association :to, factory: :version, strategy: :create
    # association :who, factory: :user, strategy: :create
    # association :created_by, factory: :user, strategy: :create

    sequence(:name) { |n| "Resource kind #{n}" }
    sequence(:description) { |n| "Description of the resource kind #{n}" }

    trait :memory do
      name { 'Main memory' }
      measurement { 'GB' }
      identity { 'MEMORY' }
      content_type { 'decimal' }
    end

    trait :cpu do
      name { 'CPUs' }
      identity { 'CPU' }
      content_type { 'positive_integer' }
    end

    trait :disk do
      name { 'Hard drive size' }
      identity { 'DISK=>SIZE' }
      measurement { 'GB' }
      content_type { 'positive_integer' }
    end

    trait :internet do
      name { 'Internet' }
      identity { 'internet' }
      content_type { 'boolean' }
    end

    trait :imaginary do
      name { 'Imaginary' }
      content_type { 'positive_integer' }
      measurement { 'm' }
    end
  end
end
