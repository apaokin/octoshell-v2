FactoryBot.define do
  factory :cloud_item, class: "CloudComputing::Item" do
    association :template, factory: :cloud_template
    association :holder, factory: :cloud_access
    after(:create) do |item|
      item.template.resources.where(editable: true).each do |resource|
        value = if resource.resource_kind.positive_integer?
                  resource.value.to_i + 1
                elsif resource.resource_kind.decimal?
                  resource.value.to_f + 1
                else
                  '1'
                end
        item.resource_items.create!(resource: resource, value: value)
      end
    end

  end
end
