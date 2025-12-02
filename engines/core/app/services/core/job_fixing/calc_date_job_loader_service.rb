module Core
  module JobFixing
    class CalcDateJobLoaderService
      class << self
        def call(cluster)
          RedisMutex.with_lock(JobFixing::CommonUtils.lock_name, block: 5) do
            config = JobFixing::CommonUtils.get_config

            raise 'Previous batch of jobs is not processed' if config['prev_not_processed']

            start_time = config['last_end_time'] || DateTime.new(2025, 1, 1)
            end_time = DateTime.current
            path = "/tmp/octoloader-#{start_time}"
            JobFixing::JobLoaderService.call(cluster, start_time, end_time, path)
            config['result_path'] = path
            config['last_end_time'] = end_time
            config['prev_not_processed'] = true
            JobFixing::CommonUtils.write_config(config)
          end
        end
      end
    end
  end
end
