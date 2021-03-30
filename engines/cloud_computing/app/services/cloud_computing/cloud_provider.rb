module CloudComputing
  class CloudProvider

    def self.vm_attributes
      %w[DISK=>SIZE internet CPU MEMORY]
    end

    def self.kinds
      @kinds ||= { 'Opennebula': Opennebula::Provider }
    end

    def self.class_from_kind(kind)
      kinds[kind]
    end


    def self.ssh_public_keys(access)
      Core::Credential.active.where(user_id: access.for.members.allowed
          .select('user_id')).select('public_key').map(&:public_key)
    end


    def self.item_hash(item)

      # hash = {
      #   'DISK=>SIZE' => ->(value) { (value.to_f * 1024).to_s },
      #   'internet' => ->(value) { [true, '1'].include?(value) },
      #   'CPU' => ->(value) { value.to_s },
      #   'MEMORY' => ->(value) {(value.to_f * 1024).to_s }
      # }

      values = { 'item_id' => item.id, 'access_id' => item.holder_id }
      values['vm_id'] = item.virtual_machine.identity if item.virtual_machine
      values['public_keys'] = ssh_public_keys(access).join("\n")
      values['template_id'] = item.template.identity

      vm_attributes.each do |key|
        r = item.resource_or_resource_item_by_identity(key)
        next unless r

        values[key] = r.value
      end
      values
    end

    def self.cloud_class(cloud)
      cloud_class = class_from_kind(cloud)

      raise "Provider for #{cloud_class.inspect} does not exist" unless cloud_class



    end

    def self.send_to_cloud(cloud, operation, params = {})
      cloud_class = class_from_kind(cloud.kind)
      raise "Provider for #{cloud.inspect} does not exist" unless cloud_class

      cloud_attributes = cloud.attributes
                               .select { |_key, value| value.present? }
      connection_attributes = {}
      cloud_attributes.each do |key, value|
        next unless key.start_with? 'remote'

        connection_attributes[key.partition('remote_').last] = value
      end
      cloud_class.connection(connection_attributes).send(operation, params)
    end


    def self.create_and_update_vms(access)

      hash = access.new_left_items.includes(:template).to_a.group_by do |item|
        item.template.cloud
      end

      hash.each do |cloud, items|
        hash_from_items = items.map { |item| item_hash(item) }
        send_to_cloud(cloud, :create_and_update_vms, hash_from_items)
      end
    end

    def self.template_list
      CloudComputing::Cloud.all.each do |cloud|
        send_to_cloud(cloud, :template_list)
      end
    end


    # def self.item_without_virtual_machine(access)
    #   access.new_left_items.without_virtual_machine
    #         .includes(:template).to_a.group do |item|
    #     item.template.cloud
    #   end
    # end
    #
    # def self.group_by_cloud(relation)
    #   relation.includes(:template).to_a.group do |item|
    #     item.template.cloud
    #   end
    # end



  end
end
