ActiveRecord::Base.transaction do
  Group.all.each do |group|
    # user = User.create!(email: "from_#{group.name}@octoshell.ru",
    #                     password: "123456", password_confirmation: '123456',
    #                     access_state: 'active')
    # p=user.profile
    # p.first_name = "Из #{group.name}"
    # p.middle_name = ""
    # p.last_name = "Иван"
    # user.activate!
		# user.groups << group
		# user.save
    # user.access_state='active'
		#
		# Core::Credential.create!(user: user, name: 'example key', public_key: Core::Cluster.first.public_key)
  end

end
