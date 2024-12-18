#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of hitobito and licensed under the
#  Affero General Public License version 3 or later. See the COPYING file at the top-level directory
#  or at https://github.com/hitobito/hitobito.

require "spec_helper"

describe BackgroundJobs::LimitConcurrentExecutions::Instrumentation do
  before do
    freeze_time
    stub_const("SampleJob", Class.new(BaseJob) do
      attr_reader :index
      self.parameters = :index
      def initialize(index = 1) = @index = index
    end)
  end

  def simulate_execution_of(job, lock: true, should_perform: true, &block)
    job.update!(locked_at: Time.zone.now, locked_by: :someone) if lock
    proc = proc {}
    instrumentation = described_class.new(job, [], &block || proc)
    if should_perform
      expect(instrumentation).to receive(:execute)
    else
      expect(instrumentation).not_to receive(:execute)
    end
    instrumentation.run
  end

  let(:settings) { Settings.delayed_jobs.concurrency }
  let(:jobs) { Delayed::Job.all }

  it "performs jobs without rescheduling" do
    first, second = 2.times.map { SampleJob.new.enqueue! }

    expect do
      simulate_execution_of(first)
      simulate_execution_of(second)
    end.not_to change { Delayed::Job.count }
  end

  context "with configured jobs" do
    before { allow(settings).to receive(:jobs).and_return(%w[SampleJob]) }

    it "re-schedules instead of performing second job" do
      first, second = 2.times.map { |i| SampleJob.new(i).enqueue! }
      expect do
        simulate_execution_of(first)
        simulate_execution_of(second, should_perform: false)
      end.to change { Delayed::Job.count }.by(1)
      rescheduled_job = Delayed::Job.where.not(id: [first.id, second.id]).first
      expect(rescheduled_job.run_at).to eq 15.seconds.from_now
      expect(rescheduled_job.payload_object.index).to eq 1
    end

    it "does not re-schedule second if it is the only job left at execution time" do
      first, second = 2.times.map { SampleJob.new.enqueue! }
      expect do
        simulate_execution_of(first)
        first.destroy
        simulate_execution_of(second)
      end.to change { Delayed::Job.count }.by(-1)
    end

    it "does not re-schedule second if first one is still queued and not processing" do
      first, second = 2.times.map { SampleJob.new.enqueue! }
      expect do
        simulate_execution_of(first, lock: false)
        simulate_execution_of(second)
      end.not_to change { Delayed::Job.count }
    end

    context "with limit of 2" do
      before { allow(settings).to receive(:limit).and_return(2) }

      it "performs both if not exceeding configured limit" do
        first, second = 2.times.map { SampleJob.new.enqueue! }
        expect do
          simulate_execution_of(first)
          simulate_execution_of(second)
        end.not_to change { Delayed::Job.count }
      end

      it "re-schedules third instead of performing if exceeding limit" do
        first, second, third = 3.times.map { SampleJob.new.enqueue! }
        expect do
          simulate_execution_of(first)
          simulate_execution_of(second)
          simulate_execution_of(third, should_perform: false)
        end.to change { Delayed::Job.count }.by(1)
      end
    end

    context "with custom reschedule_in" do
      before { allow(settings).to receive(:reschedule_in).and_return(5.seconds) }

      it "reschedules instead of performing second job with 5 seconds offset" do
        first, second = 2.times.map { SampleJob.new.enqueue! }
        expect do
          simulate_execution_of(first)
          simulate_execution_of(second, should_perform: false)
        end.to change { Delayed::Job.count }.by(1)
        rescheduled_job = Delayed::Job.where.not(id: [first.id, second.id]).first
        expect(rescheduled_job.run_at).to eq 5.seconds.from_now
      end
    end
  end
end
