module CloudComputing
  require 'main_spec_helper'
  describe Access do
    before(:each) do
      @cloud = FactoryBot.create(:cloud_cloud, kind: 'Opennebula')
      Opennebula::Provider.instance_variable_set(:@client_class, FakeOpennebulaClient)
      Opennebula::Callback.instance_variable_set(:@sleep_seconds, 0)

      @template1 = FactoryBot.create(:cloud_vm_template, cloud: @cloud)
      @project = create(:project)
    end

    describe '#copy_from_request' do
      it 'copies from request' do
        @request = CloudComputing::Request.create!(for: @project, created_by: @project.owner)
        @item2 = FactoryBot.create(:cloud_item, template: @template1, holder: @request)
        access = CloudComputing::Access.new(for: @project,
                                            user: @project.owner,
                                            allowed_by: create(:admin))
        access.copy_from_request(@request)
        access.save!
        access_resource_ids = access.items
                                    .map(&:resource_items)
                                    .flatten.map(&:resource_id)

        request_resource_ids = @request.items
                                       .map(&:resource_items)
                                       .flatten.map(&:resource_id)

        expect(access_resource_ids.sort).to eq request_resource_ids.sort

      end
    end

    describe '#merge_with' do
      it 'merges' do
        access = FactoryBot.create(:cloud_access)
        FactoryBot.create(:cloud_item, template: @template1, holder: access)
        access_resource_ids = access.items
                                    .map(&:resource_items)
                                    .flatten.map(&:resource_id)

        merge_access = FactoryBot.create(:cloud_access, for: access.for)


        expect { access.merge_with(merge_access) }
          .to change { Access.count }.by(-1)
        merge_resource_ids = merge_access.items
                                         .map(&:resource_items)
                                         .flatten.map(&:resource_id)
        expect(access.destroyed?).to eq true
        expect(merge_resource_ids.sort).to eq access_resource_ids.sort


      end
    end

    it 'covers lyfecycle' do
      @access = FactoryBot.create(:cloud_access)
      @access.for.members.create!(user: create(:user),
                                  project_access_state: 'allowed')
      @item1 = FactoryBot.create(:cloud_item, template: @template1, holder: @access)

      expect { @access.approve! }.to change { FakeOpennebulaClient.vms.count }
        .by(1).and change { ActionMailer::Base.deliveries.count }.by(1)

      expect { @access.prepare_to_finish! }.to(
        change { ActionMailer::Base.deliveries.count }.by(1)
      )
      @access.finish!
    end

    it 'prepares access  to be denied when project is assigned not active state ' do
      @access = FactoryBot.create(:cloud_access, state: 'approved',
                                  for: create(:project, state: 'active'))
      @access.for.block!
      expect(CloudComputing::Access.find_by!(for: @access.for).prepared_to_deny?).to eq true

    end

    it 'does not save access with resource item value set to < 0' do
      @access = FactoryBot.create(:cloud_access, state: 'approved',
                                  for: create(:project, state: 'active'))


      # @access = CloudComputing::Request.create!(for: @project, created_by: @project.owner)
      FactoryBot.create(:cloud_item, template: @template1, holder: @access)
      @item1 = FactoryBot.create(:cloud_item, template: @template1, holder: @access)
      FactoryBot.create(:cloud_item, template: @template1, holder: @access)

      # @access.new_left_items += [FactoryBot.build(:cloud_item, template: @template1)]


      update_hash = {}

      @item1.resource_items.each do |r_i|
        next unless r_i.resource.number?

        update_hash[r_i.id.to_s] = { 'value' => '-2', 'id' => r_i.id.to_s, 'resource_id' => r_i.resource_id.to_s }
      end

      puts 'STARTED TEST'.red

      expect(@access.update('new_left_items_attributes' => { '1' =>
        { 'id'=> @item1.id.to_s,
          'template_id' => @item1.template_id.to_s,
          'resource_items_attributes' => update_hash
        }
      })).to eq false
      puts 'UPDATED'
      pp @access.errors.to_h
      puts 'FINISHED'

      # pp @access.new_left_items.map(&:resource_items).flatten.to_a
      # pp @access.old_left_items.map(&:resource_items).flatten.to_a
      # pp @access.left_items.map(&:resource_items).flatten.to_a


      # @item1.save!
      # @access.reload
      #
      # pp @item1.resource_items


    end

  end
end
