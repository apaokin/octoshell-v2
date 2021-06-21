module CloudComputing
  require 'main_spec_helper'
  describe CloudProvider do
    before(:each) do


      if (Rails.application.secrets.cloud_computing || {})[:uri]
        begin
          url = URI((Rails.application.secrets.cloud_computing || {})[:uri])
        rescue URI::InvalidURIError => e
          raise ArgumentError, e.message, e.backtrace
        end
        connection_params = {
          user: url.user,
          password: url.password,
          host: url.host,
          port: url.port,
          path: url.path.empty? ? nil : url.request_uri,
          use_ssl: url.scheme == 'https'
        }.map do |key, value|
          ["remote_#{key}", value]
        end.to_h
        @cloud = FactoryBot.create(:cloud_cloud, connection_params.merge(
                                                 kind: 'Opennebula'))
      else
        @cloud = FactoryBot.create(:cloud_cloud, kind: 'Opennebula')
        Opennebula::Provider.instance_variable_set(:@client_class, FakeOpennebulaClient)
      end

      Opennebula::Callback.instance_variable_set(:@sleep_seconds, 1)

      @template1 = FactoryBot.create(:cloud_vm_template, cloud: @cloud,
                                                         identity: '71')
      # @template2 =  FactoryBot.create(:cloud_vm_template,
      #                                 template_kind: @template1.template_kind,
      #                                 cloud: @cloud, identity)
      @access = FactoryBot.create(:cloud_access)
      @item1 = FactoryBot.create(:cloud_item, template: @template1, holder: @access)
      @item2 = FactoryBot.create(:cloud_item, template: @template1, holder: @access)

      # 2.times do
      #   user = create(:user)
      #   @project.members.create!(user: user, project_access_state: 'allowed')
      #   key = SSHKey.generate(comment: user.email)
      #   @ssh_keys << key.ssh_public_key
      #   Core::Credential.create!(user: user, name: 'example key',
      #                            public_key: key.ssh_public_key)
      #
      # end
    end

    describe '::create_and_update_vms' do
      it 'does not create vm twice' do
        threads = []
        threads << Thread.new { CloudProvider.create_and_update_vms(@access) }
        threads << Thread.new { CloudProvider.create_and_update_vms(@access) }
        threads.each(&:join)
        $stdin.gets
        CloudProvider.finish_access(@access)
        pp(@access.new_left_items.reload.map do |i|
          [i, i.virtual_machine]
        end)
        puts 'virtual machines have been terminated'.green
        $stdin.gets
        CloudProvider.terminate_access(@access)
      end
    end
  end
end
