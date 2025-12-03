module Core
  module JobFixing
    class CalcDateJobLoaderService
      class << self
        def call(cluster)
          RedisMutex.with_lock(JobFixing::CommonUtils.lock_name, block: 5) do
            config = JobFixing::CommonUtils.get_config

            raise 'Previous batch of jobs is not processed' if config['prev_not_processed']

            start_time = config['last_end_time'] || DateTime.new(2000, 1, 1)
            end_time = DateTime.current
            path = "/tmp/octoloader-#{start_time}"
            config['cluster_name'] = cluster.description
            config['result_path'] = path
            config['last_end_time'] = end_time
            config['prev_not_processed'] = true
            JobFixing::JobLoaderService.call(cluster, start_time, end_time, path)
            JobFixing::CommonUtils.write_config(config)
          end
        end
      end
    end
  end
end
