module CloudComputing
  class Notifier

    # def self.emails
    #   %i[prepared_to_deny prepare_to_finish request_refused vm_created vm_error]
    # end

    # def self.method_missing(method, *args, **kwargs)
    #   unless respond_to_missing?(method)
    #     super
    #     return
    #   end
    #   send_email(method, *args, **kwargs)
    # end
    #
    # def self.respond_to_missing?(method_name)
    #   emails.include?(method_name.to_sym)
    #   # instance_methods(include_private).include?(method_name.to_sym)
    # end

    %i[prepared_to_deny prepared_to_finish vm_created].each do |method|
      define_singleton_method(method) do |access|
        send_email_to_each_project_member(method, access)
      end
    end

    def self.request_refused(request_id)
      send_email(:request_refused, request_id)
    end

    def self.vm_error(item_id)
      users_managing_cloud.map(&:id).each do |user_id|
        send_email(:vm_error, user_id, item_id)
      end
    end

    def self.users_managing_cloud
      User.select('distinct users')
          .joins(:permissions).where(permissions: { available: true,
                                                    action: 'manage',
                                                    subject_class: 'cloud' })
    end

    def self.send_email_to_each_project_member(method, access)
      access.for.members.allowed.map(&:user_id).each do |user_id|
        send_email(method, user_id, access.id)
      end
    end

    def self.send_email(method, *args, **kwargs)
      perform(CloudComputing::ApplicationMailer, method, *args, **kwargs)
    end

    def self.perform(klass, method, *args, **kwargs)
      return unless klass.respond_to? method

      if perform_async?
        CloudComputing::NotifierWorker.send(klass.to_s, method, *args, **kwargs)
      else
        klass.send(method, *args, **kwargs)
      end
    end

    def self.perform_async?
      false
    end

  end
end
