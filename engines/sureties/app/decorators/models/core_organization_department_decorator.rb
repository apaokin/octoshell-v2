Core::OrganizationDepartment.class_eval do
  has_many :surety_members,  class_name: 'Sureties::SuretyMember', inverse_of: :organization_department
end
