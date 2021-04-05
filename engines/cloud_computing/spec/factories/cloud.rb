FactoryBot.define do
  factory :cloud_cloud, class: "CloudComputing::Cloud" do
    sequence(:kind) { |n| "fake #{n}" }
    sequence(:name) { |n| "Cloud #{n}" }
    sequence(:description) { |n| "Description #{n}" }
    remote_host { 'localhost' }
    remote_port { '2040' }
    remote_path { nil }

    after(:create) do |cloud|
      cloud.cloud_attributes.create!(key: 'local_network_id', value: 1)
      cloud.cloud_attributes.create!(key: 'internet_network_id', value: 109)
    end

  end
end
