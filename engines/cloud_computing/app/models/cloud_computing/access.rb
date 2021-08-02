module CloudComputing
  class Access < ApplicationRecord
    include Holder
    include AASM
    include ::AASM_Additions

    belongs_to :allowed_by, class_name: 'User'
    belongs_to :user

    has_many :requests, inverse_of: :access

    accepts_nested_attributes_for :left_items,:new_left_items, :old_left_items,
                                  allow_destroy: true
    validates :for, :user, :allowed_by, presence: true
    validates :state, uniqueness: { scope: [:for_id, :for_type] }, if: :approved?

    aasm(:state) do
      state :created, initial: true
      state :approved
      state :prepared_to_finish
      state :prepared_to_deny
      state :denied
      state :finished
      event :approve do
        transitions from: :created, to: :approved do
          guard do
            self.for && items.exists? && items_filled? &&
              same_accesses.approved.empty?
          end

          after do
            requests.sent.each(&:approve!)
            create_and_update_vms
          end

        end
      end

      event :prepare_to_finish do
        transitions from: :approved, to: :prepared_to_finish
        after do
          finish_access
          Notifier.prepared_to_finish(self)
        end
      end

      event :prepare_to_deny do
        transitions from: :approved, to: :prepared_to_deny
        after do
          finish_access
          Notifier.prepared_to_deny(self)
        end
      end



      event :finish do
        transitions from: :prepared_to_finish, to: :finished
        after do
          terminate_access
        end
      end

      event :deny do
        transitions from: :prepared_to_deny, to: :denied
        after do
          terminate_access
        end
      end
    end

    def self.mergeable
      where(state: %w[approved created])
    end

    def same_accesses
      Access.where(for: self.for).where.not(id: self)
    end

    def virtual_machines
      VirtualMachine.where(item: left_items)
    end


    def copy_from_request(request)
      return unless request

      self.for = request.for
      self.user = request.created_by
      copy_items(request)
    end

    def merge_with(merge_access)
      merge_access.copy_items(self)
      merge_access.save!
      destroy!
    end

    def create_and_update_vms
      CloudProvider.create_and_update_vms(self)
    end

    def terminate_access
      CloudProvider.terminate_access(self)
    end

    def finish_access
      CloudProvider.finish_access(self)
    end

    def reinstantiate
      create_and_update_vms
    end

    def reinstantiate?
      new_left_items.any? do |item|
        !item.virtual_machine
      end || old_left_items.any?
    end

    def add_keys
      # OpennebulaTask.add_keys(id)
      TaskWorker.perform_async(:add_keys, id)
    end

    def record_new_synchronization_date_time
      update!(started_sync_at: DateTime.now, finished_sync_at: nil)
    end

    def record_synchronization_finish_date_time
      update!(finished_sync_at: DateTime.now)
    end

    def vm_created
      Notifier.vm_created(self)
    end

    def copy_items(holder)
      pos_hash = Hash[holder.items.map do |item|
        [item, add_item(item)]
      end]
      holder.items.each do |item|
        from_item = pos_hash[item]
        item.from_links.each do |link|
          from_item.from_links.new(to: pos_hash[link.to])
        end
      end
    end

    private

    def add_item(item)
      pos = if item.item_in_access
              old_left_items.new(item.slice('template_id', 'item_id'))
            else
              new_left_items.new(item.slice('template_id', 'item_id'))
            end

      item.resource_items.each do |r_p|
        pos.resource_items
           .build(r_p.attributes.slice('resource_id', 'value'))
      end
      pos
    end

  end
end
