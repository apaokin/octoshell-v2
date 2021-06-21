
module CloudComputing
  class TaskWorker
    include Sidekiq::Worker
    sidekiq_options retry: 2, queue: :cloud_computing_task_worker

    def perform(method, *args, **kwargs)
      CloudComputing::CloudProvider.send(method, *args, **kwargs)
    end
  end
end
