module CloudComputing
  class CloudProvider

    def self.vm_attributes
      %w[DISK=>SIZE internet CPU MEMORY SET_HOSTNAME]
    end

    def self.kinds
      @kinds ||= { 'Opennebula' => Opennebula::Provider }
    end

    def self.class_from_kind(kind)
      kinds[kind]
    end


    def self.ssh_public_keys(access)
      Core::Credential.active.where(user_id: access.for.members.allowed
          .select('user_id')).select('public_key').map(&:public_key)
    end

    def self.terminate_item(item)
      values = { 'item_id' => item.id, 'access_id' => item.holder_id }
      values['vm_id'] = item.virtual_machine.identity if item.virtual_machine
      values['template_id'] = item.template.identity
      vm_attributes.each do |key|
        r = item.resource_or_resource_item_by_identity(key)
        next if r.nil?

        values[key] = r.value
      end
      values
    end

    def self.item_hash(item)
      values = terminate_item(item)
      values['public_keys'] = ssh_public_keys(item.holder).join("\n")
      values
    end

    def self.cloud_class(cloud)
      cloud_class = class_from_kind(cloud)
      raise "Provider for #{cloud_class.inspect} does not exist" unless cloud_class
    end

    def self.perform_async?
      true
    end

    def self.send_to_cloud_async(cloud, operation, *args)
      if perform_async?
        TaskWorker.perform_async(:send_to_cloud, cloud.id, operation, *args)
      else
        send(:send_to_cloud, cloud.id, operation, *args)
      end
    end

    def self.send_to_cloud(cloud_r, operation, *args)
      cloud = if cloud_r.is_a?(Integer)
                Cloud.find(cloud_r)
              else
                cloud_r
              end
      cloud_class = class_from_kind(cloud.kind)
      raise "Provider for #{cloud.inspect} does not exist" unless cloud_class

      cloud_attributes = cloud.attributes
                              .select { |_key, value| value.present? }
      connection_attributes = {}
      cloud_attributes.each do |key, value|
        next unless key.start_with? 'remote'

        connection_attributes[key.partition('remote_').last] = value
      end
      cloud_class.connection(connection_attributes).send(operation, *args)
    end

    def self.show(access)
      hash = access.new_left_items.includes(:template).to_a.group_by do |item|
        item.template.cloud
      end
      hash.each do |cloud, items|
        hash_from_items = items.map { |item| terminate_item(item) }
        env_params = cloud.cloud_attributes
                          .map { |a| [a.key, a.value] }.to_h
        send_to_cloud_async(cloud, :show, hash_from_items, env_params)
      end
    end

    def self.execute_action(item_id, action)
      item = CloudComputing::Item.find(item_id)
      cloud = item.template.cloud
      hash = terminate_item(item).merge('action' => action)
      env_params = cloud.cloud_attributes
                        .map { |a| [a.key, a.value] }.to_h
      send_to_cloud_async(cloud, :execute_action, [hash], env_params)
    end

    def self.receive_on_execute_action(results)
      results.each do |result|
        next if !result['item_id'] || !result['access_id']

        item = CloudComputing::Item.find(result['item_id'])
        add_messages(item, result)
        next unless result['vm_id']

        update_virtual_machine(item, result)
      end

    end

    def self.receive_on_show(results)

      results.each do |result|
        next if !result['item_id'] || !result['access_id']

        item = CloudComputing::Item.find(result['item_id'])
        add_messages(item, result)
        next unless result['vm_id']

        update_virtual_machine(item, result)
      end
    end



    def self.finish_access(access)
      hash = access.new_left_items.includes(:template).to_a.group_by do |item|
        item.template.cloud
      end
      access.record_new_synchronization_date_time
      hash.each do |cloud, items|
        hash_from_items = items.map { |item| terminate_item(item) }
        env_params = cloud.cloud_attributes
                          .map { |a| [a.key, a.value] }.to_h
        send_to_cloud_async(cloud, :finish_access, hash_from_items,
                      env_params)
      end
    end

    def self.terminate_access(access)
      hash = access.new_left_items.includes(:template).to_a.group_by do |item|
        item.template.cloud
      end
      access.record_new_synchronization_date_time

      hash.each do |cloud, items|
        hash_from_items = items.map { |item| terminate_item(item) }
        env_params = cloud.cloud_attributes
                          .map { |a| [a.key, a.value] }.to_h
        send_to_cloud_async(cloud, :terminate_access, hash_from_items,
                      env_params)
      end
    end

    def self.receive_on_terminate_access(results)
      results.each do |result|
        next if !result['item_id'] || !result['access_id']

        item = CloudComputing::Item.find(result['item_id'])
        add_messages(item, result)
      end
      access_id = (results.first || {})['access_id']
      return unless access_id

      CloudComputing::Access.find(access_id).record_synchronization_finish_date_time

    end

    def self.receive_on_finish_access(results)
      results.each do |result|
        next if !result['item_id'] || !result['access_id']

        item = CloudComputing::Item.find(result['item_id'])
        add_messages(item, result)
        next unless result['vm_id']

        update_virtual_machine(item, result)
      end

      access_id = (results.first || {})['access_id']
      return unless access_id

      CloudComputing::Access.find(access_id).record_synchronization_finish_date_time

    end

    def self.create_and_update_vms(access)

      hash = access.new_left_items.includes(:template).to_a.group_by do |item|
        item.template.cloud
      end

      access.record_new_synchronization_date_time

      hash.each do |cloud, items|
        hash_from_items = items.map { |item| item_hash(item) }
        env_params = cloud.cloud_attributes
                          .map { |a| [a.key, a.value] }.to_h
        send_to_cloud_async(cloud, :create_and_update_vms, hash_from_items,
                      env_params)
      end
    end

    def self.template_list
      CloudComputing::Cloud.all.each do |cloud|
        send_to_cloud_async(cloud, :template_list, 'cloud_id' => cloud.id)
      end
    end

    def self.receive_on_template_list(hash)
      return true unless hash['success']

      kind = CloudComputing::TemplateKind.virtual_machine_cloud_class
      return unless kind

      kind.load_templates(hash['data'])

    end

    def self.add_messages(item, result)
      error_detected = false
      changed = false

      (vm_attributes + [nil]).each do |attribute|
        messages = if attribute.nil?
                     result['messages'] || []
                   else
                     (result[attribute] || {})['messages'] || []
                   end
        messages.each do |msg|
          changed = true
          if !msg[0] && !error_detected
            error_detected = true
            Notifier.vm_error(item.id)
          end

          item.api_logs.create!(
            success: msg[0],
            action: msg[1],
            log: msg[2],
            code: msg[3],
            resource: attribute
          )
        end
      end
      changed
    end

    def self.update_virtual_machine(item, result)
      virtual_machine = item.virtual_machine ||
                        item.create_virtual_machine!(identity: result['vm_id'])
      if result['local_network_id'] == false
        virtual_machine.inner_address = nil
      elsif result['local_network_id']
        virtual_machine.inner_address = result['local_network_id']
      end

      if result['internet_network_id'] == false
        virtual_machine.internet_address = nil
      elsif result['internet_network_id']
        virtual_machine.internet_address = result['internet_network_id']
      end
      if result['state']
        virtual_machine.state = result['state']
        virtual_machine.lcm_state = result['lcm_state']

        CloudComputing::VirtualMachine.locale_columns(:human_state, :description).each do |col|
          virtual_machine.send("#{col}=", result[col.to_s])
        end
      end
      virtual_machine.last_info = DateTime.now

      virtual_machine.update_actions(result['actions']) if result['actions']
      virtual_machine.save!
    end

    def self.update_resources(item, result)
      vm_attributes.each do |key|

        next unless result[key]

        next unless result[key]['success']

        r = item.resource_or_resource_item_by_identity(key)
        if r.is_a?(ResourceItem) && r.item.item_in_access
          r.access_resource_item.update!(value: r.value)
          r.item.destroy unless r.item.resource_items.any?
          r.destroy
        end
      end
    end

    def self.receive_on_create_and_update_vms(results)
      changed = false
      results.each do |result|
        next if !result['item_id'] || !result['access_id']

        item = CloudComputing::Item.find(result['item_id'])
        if add_messages(item, result)
          changed = true
        end

        next unless result['vm_id']

        update_virtual_machine(item, result)
        update_resources(item, result)
      end
      access_id = (results.first || {})['access_id']
      return unless access_id

      access = CloudComputing::Access.find(access_id)

      access.record_synchronization_finish_date_time
      access.vm_created if changed

    end
  end
end
