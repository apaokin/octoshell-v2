require 'main_spec_helper'
module Jobstat
  def self.create_job(attributes = {})
    Jobstat::Job.create!(FactoryBot.build(:job, attributes).attributes)
  end

  describe RunNodeService do
    describe "#call" do
      it "ok" do
        now = DateTime.now
        [
          [1, 1.hours],
          [2, 2.hours],
          [3, 3.hours],
          [16, 4.hours],
          [8, 3.hours]
        ].each do |r|
          Jobstat.create_job(num_nodes: r[0], start_time: now - r[1],
                             end_time: now, login: 'tester')

        end
        service = RunNodeService.new(Jobstat::Job.where(login: 'tester'), 4, 4)
        pp service.call




      end


    end
    describe 'agg_hours_nodes' do

      it 'shows min, max correctly' do
        now = DateTime.now
        Jobstat.create_job(num_nodes: 1, start_time: now - 1.hours, end_time: now, login: 'tester')
        Jobstat.create_job(num_nodes: 7, start_time: now - 2.hours, end_time: now, login: 'tester')
        service = RunNodeService.new(Jobstat::Job.where(login: 'tester'))
        # expect(service.send(:agg_hours_nodes)).to eq([1.0, 2.0, 1, 7])
      end
    end
  end
end
