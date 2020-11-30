User.class_eval do

  has_many :surety_members, class_name: "::Sureties::SuretyMember", dependent: :destroy
  has_many :sureties, through: :surety_members, class_name: "::Sureties::Surety"

  has_many :authored_sureties, class_name: "::Sureties::Surety", foreign_key: :author_id, inverse_of: :author

end
