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
      @item1 = FactoryBot.create(:cloud_item, template: @template1, holder: @access, id: 100)
      @item2 = FactoryBot.create(:cloud_item, template: @template1, holder: @access, id: 101)

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
      it 'creates, updates, deletes vms successfully' do
        CloudProvider.create_and_update_vms(@access)
        pp(@access.new_left_items.map do |i|
          [i, i.virtual_machine,
           i.all_resources.map { |r| r.attributes.merge(kind: r.resource_kind.name, class: r.class ) }]
        end)
        pp @access.items.map(&:api_logs)
        puts 'virtual machines have been created'.green
        $stdin.gets
        CloudProvider.create_and_update_vms(@access)
        pp(@access.new_left_items.reload.map do |i|
          [i, i.virtual_machine,
           i.all_resources.map { |r| { id: r.id,
                                       kind: r.resource_kind.name,
                                       class: r.class.to_s,
                                       value: r.value } }]
        end)
        puts 'virtual machines have not been updated'.green

        # @access.create!()
        @access.new_left_items.each do |item|
          new_item = @access.items.create!(holder: @access, item_in_access: item,
                                           template: item.template)

          item.resource_items.each do |item_resource|
            value = if item_resource.resource.resource_kind.positive_integer?
                      item_resource.value.to_i + 1
                    elsif item_resource.resource.resource_kind.decimal?
                      item_resource.value.to_f + 1
                    elsif item_resource.resource.resource_kind.text?
                      'CHANGED_DEFAULT_AAAAAA'
                    else
                      '0'
                    end
            new_item.resource_items.create!(resource: item_resource.resource,
                                            value: value)
          end
        end
        2.times do
          user = create(:user)
          @access.for.members.create!(user: user, project_access_state: 'allowed')
          key = SSHKey.generate(comment: user.email)
          Core::Credential.create!(user: user, name: 'example key',
                                   public_key: key.ssh_public_key)
        end

        $stdin.gets
        CloudProvider.create_and_update_vms(@access)
        pp(@access.new_left_items.reload.map do |i|
          [i, i.virtual_machine,
           i.all_resources.map { |r| { id: r.id,
                                       kind: r.resource_kind.name,
                                       class: r.class.to_s,
                                       value: r.value } }]
        end)
        puts 'virtual machines have been updated'.green
        $stdin.gets
        CloudProvider.finish_access(@access)
        pp(@access.new_left_items.reload.map do |i|
          [i, i.virtual_machine]
        end)
        puts 'virtual machines have been terminated'.green
        $stdin.gets
        CloudProvider.terminate_access(@access)


        #
        # puts FakeOpennebulaClient
      end
    end


  end
end
