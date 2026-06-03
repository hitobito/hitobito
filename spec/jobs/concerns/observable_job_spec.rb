#  Copyright (c) 2012-2026, Puzzle ITC. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "spec_helper"

describe ObservableJob do
  include DelayedJobSpecHelper

  let(:person) { people(:top_leader) }

  context "with logged in person" do
    before do
      allow(Auth).to receive(:current_person).and_return(person)
    end

    it "should enqueue job" do
      job = Test::SuccessfulObservableJob.new

      expect { job.enqueue! }.to change { JobObservation.count }.by(1)
    end

    it "should create job observation when enqueued" do
      job = Test::SuccessfulObservableJob.new

      expect(JobObservation).to receive(:create!).with({
        person:,
        job_class: "Test::SuccessfulObservableJob",
        filename: nil,
        filetype: nil,
        reports_progress: false,
        max_attempts: nil
      }).and_call_original

      job.enqueue!
    end

    it "should create job observation with job specific number of max attempts" do
      job = Test::SuccessfulObservableJob.new
      job.define_singleton_method(:max_attempts) { 3 }

      expect(JobObservation).to receive(:create!)
        .with(hash_including(max_attempts: 3))
        .and_call_original
      job.enqueue!
    end

    it "should have reference to job observation when enqueued" do
      job = Test::SuccessfulObservableJob.new
      job.enqueue!

      expect(job.job_observation).not_to be_nil
    end

    it "should not enqueue job when creating job observation fails" do
      job = Test::SuccessfulObservableJob.new
      allow(JobObservation)
        .to receive(:create!)
        .and_raise("Test exception: Could not create job observation")

      expect { job.enqueue! }
        .to raise_exception("Test exception: Could not create job observation")
        .and change { JobObservation.count }.by(0)
        .and change { Delayed::Job.count }.by(0)
    end

    it "should not create job observation when enqueueing of delayed job fails" do
      job = Test::UnsuccessfulObservableJob.new
      job.define_singleton_method(:enqueue!) do
        raise "Test exception: Something went wrong while enqueueing job"
      end

      expect { job.enqueue! }
        .to raise_exception("Test exception: Something went wrong while enqueueing job")
        .and change { JobObservation.count }.by(0)
        .and change { Delayed::Job.count }.by(0)
    end

    it "should report status in_progress when job is being worked off" do
      job = Test::SuccessfulObservableJob.new
      enqueued_job = job.enqueue!
      job_observation = job.job_observation

      expect(job_observation).to receive(:report_in_progress!)
      run_enqueued_job(enqueued_job)
    end

    it "should report status success when job has been worked off without any errors" do
      job = Test::SuccessfulObservableJob.new
      enqueued_job = job.enqueue!
      job_observation = job.job_observation

      expect(job_observation).to receive(:report_success!).with(1)
      expect { run_enqueued_job(enqueued_job) }.to change(Delayed::Job, :count).by(-1)
    end

    it "should increase attempt number after failure and reschedule job" do
      job = Test::UnsuccessfulObservableJob.new
      enqueued_job = job.enqueue!
      job_observation = job.job_observation

      expect(job_observation).to receive(:report_error!).with(1)
      run_enqueued_job(enqueued_job)
    end

    it "should have status error when last job retry failed" do
      job = Test::UnsuccessfulObservableJob.new
      enqueued_job = job.enqueue!
      job_observation = job.job_observation

      expect(job_observation).to receive(:report_failure!)
      2.times { run_enqueued_job(enqueued_job) }
    end

    it "should report progress" do
      job = Test::ObservableJobWithProgress.new
      enqueued_job = job.enqueue!
      job_observation = job.job_observation

      expect(job_observation).to receive(:report_progress!).exactly(5).times
      run_enqueued_job(enqueued_job)
    end

    it "should not create job observation when user_id is explicitly set to nil" do
      job = Test::SuccessfulObservableJob.new
      job.user_id = nil

      expect(JobObservation).not_to receive(:create!)
      job.enqueue!
      expect(job.instance_variable_get(:@job_observation_id)).to be_nil
    end

    it "should successfully run job even if redis error occurs during broadcast" do
      job = Test::SuccessfulObservableJob.new
      enqueued_job = job.enqueue!
      job_observation = job.job_observation

      expect(job_observation).to receive(:report_success!).with(1).and_call_original
      allow(job_observation).to receive(:broadcast_replace_to).and_raise(Redis::ConnectionError).twice
      expect(Sentry).to receive(:capture_exception).with(Redis::ConnectionError).twice

      expect(run_enqueued_job(enqueued_job)).to be_truthy
    end
  end

  context "without logged in person" do
    it "should not create job observation when enqueued" do
      job = Test::SuccessfulObservableJob.new

      expect(JobObservation).not_to receive(:create!)
      job.enqueue!
      expect(job.instance_variable_get(:@job_observation_id)).to be_nil
    end

    it "should successfully complete job" do
      enqueued_job = Test::ObservableJobWithProgress.new.enqueue!

      expect do
        run_enqueued_job(enqueued_job)
      end.to change { Delayed::Job.count }.by(-1)
    end

    it "should fail with expected exception" do
      enqueued_job = Test::UnsuccessfulObservableJob.new.enqueue!
      run_enqueued_job(enqueued_job)

      expect(enqueued_job.last_error).to include("Test exception: Something went wrong during job execution")
    end
  end

  context "nested jobs" do
    it "should enqueue jobs from another job and correctly assign them to a user" do
      job = Test::ObservableParentJob.new
      job.user_id = person.id

      expect { enqueue_and_run_job(job) }
        .to change { Delayed::Job.count }.by(3)
        .and change { JobObservation.where(person_id: person.id).count }.by(4)

      expect(Delayed::Worker.new.work_off).to match_array([3, 0])
    end
  end

  context "job observation id" do
    it "has job_observation_id in the parameters array of all observable jobs", :aggregate_failures do
      Rails.autoloaders.main.eager_load_dir("app/jobs")

      observable_job_classes = ObjectSpace.each_object(Class).select do |klass|
        klass.ancestors.include?(ObservableJob)
      end

      observable_job_classes.each do |observable_job_class|
        error_message = <<~MSG
          Expected #{observable_job_class}.parameters to include :job_observation_id but it didn't.

          This can usually be solved by replacing:
            self.parameters = [:some_param]
          with:
            self.parameters += [:some_param]
        MSG

        expect(observable_job_class.parameters).to include(:job_observation_id), error_message
      end
    end
  end
end
