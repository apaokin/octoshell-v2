FactoryBot.define do
  factory :cloud_access, class: "CloudComputing::Access" do
    association :for, factory: :project
    association :user, factory: :user
    association :allowed_by, factory: :admin
  end
end
