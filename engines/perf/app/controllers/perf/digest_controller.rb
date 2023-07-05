module Perf
  class DigestController < ApplicationController
    def run_time
      @jobs = Perf::Job.limit(100).to_a.each_with_index.map do |job, i|
        job.attributes.merge(
          'run_time' => hour_diff(job.end_time, job.start_time),
          'index' => i,
          'human' => job.human
        )
      end
      @jobs = @jobs.to_json.html_safe
    end

    private

    def hour_diff(last, first)
      last && first && ((last - first) / 3600).round
    end

  end
end
