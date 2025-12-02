module Core
  module JobFixing
    class JobLoaderService
      def self.call(cluster, start_time, end_time, path)
        new(cluster, start_time, end_time, path).run_commands
      end

      def initialize(cluster, start_time, end_time, path)
        @cluster = cluster
        @start_time = start_time.strftime('%Y-%m-%dT%H:%M:%S')
        @end_time = end_time.strftime('%Y-%m-%dT%H:%M:%S')
        @path = path
        @connection_to_cluster = Net::SSH.start(@cluster.host,
                                                @cluster.admin_login,
                                                key_data: @cluster.private_key)
      end

      def run_commands
        result = run_on_cluster "sudo /opt/octo/show_jobs.sh #{@start_time} #{@end_time}"
        File.delete(@path) if File.exist? @path
        File.open(@path, 'wb', 0o600) { |f| f.write result }
      ensure
        @connection_to_cluster.close
      end

      private

      def run_on_cluster(command)
        @connection_to_cluster.exec!(command)
      end
    end
  end
end
