
module CloudComputing
  class NotifierWorker
    include Sidekiq::Worker
    sidekiq_options retry: 2, queue: :cloud_computing_notifier_worker

    def perform(class_name, method, *args)
      # puts class_name
      # puts method
      # puts args.inspect
      Object.const_get(class_name).send(method, *args).deliver!
    end
  end
end
