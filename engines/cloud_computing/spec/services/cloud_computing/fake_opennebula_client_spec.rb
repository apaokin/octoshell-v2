module CloudComputing
  require 'main_spec_helper'
  describe CloudProvider do
    before(:each) do
      @cloud = FactoryBot.create(:cloud_cloud, kind: 'Opennebula')
      Opennebula::Provider.instance_variable_set(:@client_class, FakeOpennebulaClient)
      Opennebula::Callback.instance_variable_set(:@sleep_seconds, 1)

      @template1 =  FactoryBot.create(:cloud_vm_template, cloud: @cloud)
      @template2 =  FactoryBot.create(:cloud_vm_template,
                                      template_kind: @template1.template_kind,
                                      cloud: @cloud)

      @access = FactoryBot.create(:cloud_access)
      @item1 = FactoryBot.create(:cloud_item, template: @template1, holder: @access)
    end

    describe '::create_and_update_vms' do
      it 'creates, updates, deletes vms successfully' do
        CloudProvider.create_and_update_vms(@access)
        pp(@access.new_left_items.map do |i|
          [i, i.virtual_machine,
           i.all_resources.map { |r| r.attributes.merge(kind: r.resource_kind.name, class: r.class ) }]
        end)
        puts 'virtual machines have been created'.green
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
                      'CHANGED_DEFAULT_AAAAAAA'
                    else
                      '0'
                    end
            new_item.resource_items.create!(resource: item_resource.resource,
                                            value: value)
          end
        end
        2.times do
          user = create(:user)
          key = SSHKey.generate(comment: user.email)
          Core::Credential.create!(user: user, name: 'example key',
                                   public_key: key.ssh_public_key)
          @access.for.members.create!(user: user, project_access_state: 'allowed')

        end

        CloudProvider.create_and_update_vms(@access)
        pp(@access.new_left_items.reload.map do |i|
          [i, i.virtual_machine,
           i.all_resources.map { |r| { id: r.id,
                                       kind: r.resource_kind.name,
                                       class: r.class.to_s,
                                       value: r.value } }]
        end)
        puts 'virtual machines have been updated'.green

        CloudProvider.finish_access(@access)
        pp(@access.new_left_items.reload.map do |i|
          [i, i.virtual_machine]
        end)
        puts 'virtual machines have been terminated'.green

        CloudProvider.terminate_access(@access)
      end

      it 'does not create a vm twice' do
        expect{CloudComputing::Opennebula::Provider.new({}).create_and_update_vms(
          @access.new_left_items.map do |item|
            {
              'access_id' => @access.id,
              'item_id' => item.id,
              'template_id' => item.template_id
            }
          end)}.to change{FakeOpennebulaClient.vms.count}.by(1)

          expect{CloudComputing::Opennebula::Provider.new({}).create_and_update_vms(
            @access.new_left_items.map do |item|
              {
                'access_id' => @access.id,
                'item_id' => item.id,
                'template_id' => item.template_id
              }
            end)}.to change{FakeOpennebulaClient.vms.count}.by(0)


      end
    end

    describe '::execute_action' do
      before(:each) do
        CloudProvider.create_and_update_vms(@access)
      end
      it '::does not execute action when the vm is in an error state' do
        #assign error state
        error_state = Opennebula::State.detect(&:error_alias?)
        FakeOpennebulaClient.vms.each do |vm|
          vm['VM']['STATE'] = error_state.state_id.to_s
          vm['VM']['LCM_STATE'] = error_state.lcm_state_id.to_s
        end
        CloudProvider.execute_action(@access.new_left_items.first.id, 'some_action')
      end

      it '::does not execute action when the vm is in bad state' do
        CloudProvider.execute_action(@access.new_left_items.first.id, 'some_action')
      end

      it '::executes action' do
        CloudProvider.execute_action(@access.new_left_items.first.id, 'reboot')
        log_row = FakeOpennebulaClient.logger.select do |row|
          row[0] == 'vm.action' && row[1] == 'reboot'
        end
        expect(log_row).to be_truthy
        pp @access.new_left_items.map(&:api_logs)

      end


    end
  end
end
