module CloudComputing
  require 'main_spec_helper'
  describe CloudProvider do
    before(:each) do
      @template1 =  FactoryBot.create(:cloud_vm_template)
      @template2 =  FactoryBot.create(:cloud_vm_template, template_kind: @template1.template_kind)

      @access = FactoryBot.create(:cloud_access)
      @item1 = FactoryBot.create(:cloud_item, template: @template1, holder: @access)
      @item2 = FactoryBot.create(:cloud_item, template: @template2, holder: @access)

      # FactoryBot.create(:cloud_vm_template_kind )

      # CloudComputing::SupportMethods.seed
      #
      # @project = create(:project)
      # @ssh_keys = []
      # 2.times do
      #   user = create(:user)
      #   @project.members.create!(user: user, project_access_state: 'allowed')
      #   key = SSHKey.generate(comment: user.email)
      #   @ssh_keys << key.ssh_public_key
      #   Core::Credential.create!(user: user, name: 'example key',
      #                            public_key: key.ssh_public_key)
      #
      # end
      # #
      # user_without_active_key = create(:user)
      # key = SSHKey.generate(comment: user_without_active_key.email)
      # Core::Credential.create!(user: user_without_active_key, name: 'example key',
      #                          state: 'deactivated',
      #                          public_key: key.ssh_public_key)
      # @project.users << user_without_active_key
      # @project.users << create(:user)
      # #
      # @template = CloudComputing::TemplateKind.virtual_machine_cloud_class.templates.first
      # @access = CloudComputing::Access.create!(for: @project,
      #                                          user: @project.owner,
      #                                          allowed_by: create(:admin))
      # CloudComputing::SupportMethods.add_positions(@access, @template)

    end

    if ENV['OPENNEBULA_URI']
      context 'opennebula api methods' do
        it 'shows templates' do
          
        end
      end

    end

    describe '::create_and_update_vms' do
      it 'displays hash' do
        CloudProvider.create_and_update_vms(@access)
      end
    end

    describe '::item_hash' do
      it 'displays hash' do
      end
    end
  end
end
