Core::Project.class_eval do
  has_many :sureties, inverse_of: :project,  class_name: 'Sureties::Surety'
  accepts_nested_attributes_for :sureties

  def members_for_new_surety
    members.joins(:user).where(project_access_state: :engaged,
                                users: { access_state: 'active'})
  end

end
