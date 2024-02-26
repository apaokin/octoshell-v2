module Jobstat
  class RunNodeService

    def self.ar_class
      Jobstat::Job
    end

    def self.attributes
      {
        'run_hours' => 'EXTRACT(EPOCH FROM jobstat_jobs.end_time - jobstat_jobs.start_time) / 3600',
        'wait_hours' => 'EXTRACT(EPOCH FROM jobstat_jobs.start_time - jobstat_jobs.submit_time) / 3600'
      }.merge(ar_class.columns_hash.keys.map { |k| [k, k] }.to_h )
    end

    def self.agg_funcs
      %w[avg min max]
    end


    def form_width_bins(min, max, n)
      s = (max - min) / n
      n.times map do |i|
        min + s * i
      end
    end

    def real_run_hours
      'EXTRACT(EPOCH FROM jobstat_jobs.end_time - jobstat_jobs.start_time) / 3600'
    end

    def run_hours

      'jobstat_jobs.timelimit / 3600'
    end

    def initialize(relation, run_bins = nil, node_bins = nil)
      @relation = relation
      @run_bins = run_bins
      @node_bins = node_bins
      @min_run, @max_run, @min_node, @max_node = *agg_hours_nodes
    end

    def self.valid?(name)
      agg = agg_funcs.detect do |a|
        name.to_s.end_with?(a)
      end
      agg && attributes.keys.include?(name.to_s.rpartition("_#{agg}").first)
    end

    def extras
      [2, 4, 10].map do |i|
        name = "extra_#{i}"
        [name, Arel.sql("AVG(CASE WHEN (#{extra_time} >= #{i}) THEN 1 ELSE 0 END) ").as(name)]
      end.to_h
    end


    def call
      @relation.group(run_sql, node_sql)
               .select(run_sql.as('run_bin'), node_sql.as('node_bin'), 'count(id)',
                       *extras.values)
               .to_a.map(&:attributes)
               .sort do |a, b|
                 r = a['run_bin'] <=> b['run_bin']
                 r.zero? ? a['node_bin'] <=> b['node_bin'] : r
               end.map do |h|
                 h['run_bin_human'] = run_node(h['run_bin'])
                 h['node_bin_human'] = node_bin_human(h['node_bin'])
                 h
               end.group_by { |r| r['run_bin'] }

    end

    def node_bin_human(num)
      left = @min_node + @node_bin_size * num
      right = left + @node_bin_size
      # ["[1, 3]", '[4, 13]', '[14, 39]'][num]
      "[#{(2**left).floor}, #{(2**right).floor})"

    end

    def run_node(num)
      left = @min_run + @run_bin_size * num
      right = left + @run_bin_size
      "[#{left}, #{right})"
    end

    # def run_hours
    #   'EXTRACT(epoch FROM end_time - start_time)/3600'
    # end

    def extra_time
      "((timelimit / 3600) /  (#{real_run_hours}))"
    end

    def extra_hours

    end


    private

    def run_sql
      @run_bins = @min_run == @max_run ? 1 : 4 if @run_bins.nil?
      @run_bin_size = (@max_run - @min_run) / @run_bins
      Arel.sql <<-SQL
        floor(( #{run_hours} - #{@min_run} ) / #{@run_bin_size} )::numeric::integer
      SQL
    end

    def node_sql
      @node_bins = @min_node == @max_node ? 1 : @max_node.floor - @min_node.floor if @node_bins.nil?
      @node_bin_size = (@max_node - @min_node) / @node_bins
      Arel.sql <<-SQL
        floor((log(2, jobstat_jobs.num_nodes) - #{@min_node} ) / #{@node_bin_size} )::numeric::integer
      SQL
    end

    def agg_hours_nodes
      @relation.select([[run_hours, 'run'], ['log(2, num_nodes)', 'node']].map do |d|
        %w[minimum maximum].map do |agg|
          Arel.sql(d[0]).send(agg).as("#{agg}_#{d[1]}")
        end
      end.flatten).to_a.first.attributes.values[1..]
    end





  end
end
