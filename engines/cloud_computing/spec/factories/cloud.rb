FactoryBot.define do
  factory :cloud_cloud, class: "CloudComputing::Cloud" do
    sequence(:kind) { |n| "fake #{n}" }
    sequence(:name) { |n| "Cloud #{n}" }
    sequence(:description) { |n| "Description #{n}" }
    remote_host { 'localhost' }
    remote_port { '2040' }
    remote_path { nil }

    # after(:create) do |cloud|
    #   cloud
    # end

  end
end
