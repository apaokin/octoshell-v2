module Core
  module JobFixing
    class ParseAndUpdateService
      class << self
        def call
          RedisMutex.with_lock(JobFixing::CommonUtils.lock_name, block: 5) do
            new(path).process
          end
        end

        def initialize
          config = CommonUtils.get_config
          @file_path = config['result_path']
          @last_end_time = config['last_end_time']
          @header = %w[JobIDRaw State NodeList NNodes NCPUS]

        end


        private

        def log

        end

        def process
          parse

        end

        def parse

          File.read(@file_path).split("\n").each do |row|

          end
        end

        def fix_num_nodes(array)
          values_list = records.map do |record|
            "(#{record[unique_by]}, '#{record[:status]}', #{record[:priority]})"
          end.join(", ")
          # header:   %w[JobIDRaw State NodeList NNodes NCPUS]

          sql = <<~SQL
             UPDATE jobstat_jobs
             SET
               num_nodes = data.num_nodes,
               nodelist = data.nodelist,
               num_cores = data.num_cores,
             FROM (VALUES #{values_list}) AS data(id, state, nodelist, num_nodes, num_cores)
             WHERE users.id = data.id
             RETURNING users.id;
           SQL
        end

      end
    end
  end
end
