
module CloudComputing
  class NotifierWorker
    include Sidekiq::Worker
    sidekiq_options retry: 2, queue: :cloud_computing_notifier_worker

    def perform(class_name, method, *args, **kwargs)
      Object.const_get(class_name).try(method, *args, **kwargs)
    end
  end
end
