#  Copyright (c) 2012-2026, Puzzle ITC. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "spec_helper"

describe UserManageableJob do
  include DelayedJobSpecHelper

  let(:person) { people(:top_leader) }

  context "with logged in person" do
    before do
      allow(Auth).to receive(:current_person).and_return(person)
    end

    it "should create default user job result when enqueued" do
      job = Examples::SuccessfulUserManagedJob.new

      expect(UserJobResult).to receive(:create_default!).and_call_original
      job.enqueue!
    end

    it "should not enqueue delayed job when creating user job result fails" do
    end

    it "should not create user job result when enqueing of delayed job fails" do
    end

    it "should have reference to user job result when job is enqueued" do
      job = Examples::SuccessfulUserManagedJob.new
      job.enqueue!

      expect(job.user_job_result).not_to be_nil
    end

    it "should report status in_progress when job is being worked off" do
      job = Examples::SuccessfulUserManagedJob.new
      enqueued_job = job.enqueue!
      user_job_result = job.user_job_result

      expect(user_job_result).to receive(:report_in_progress!)
      run_enqueued_job(enqueued_job)
    end

    it "should report status success when job has been worked off without any errors" do
      job = Examples::SuccessfulUserManagedJob.new
      enqueued_job = job.enqueue!
      user_job_result = job.user_job_result

      expect(user_job_result).to receive(:report_success!).with(1)
      expect { run_enqueued_job(enqueued_job) }.to change(Delayed::Job, :count).by(-1)
    end

    it "should increase attempt number after failure and reschedule job" do
      job = Examples::UnsuccessfulUserManagedJob.new
      enqueued_job = job.enqueue!
      user_job_result = job.user_job_result

      expect(user_job_result).to receive(:report_error!).with(1)
      run_enqueued_job(enqueued_job)
    end

    it "should have status error when last job retry failed" do
      job = Examples::UnsuccessfulUserManagedJob.new
      enqueued_job = job.enqueue!
      user_job_result = job.user_job_result

      expect(user_job_result).to receive(:report_failure!)
      2.times { run_enqueued_job(enqueued_job) }
    end

    it "should report progress" do
      job = Examples::UserManagedJobWithProgress.new
      enqueued_job = job.enqueue!
      user_job_result = job.user_job_result

      expect(user_job_result).to receive(:report_progress!).exactly(5).times
      run_enqueued_job(enqueued_job)
    end
  end

  context "without logged in person" do
    it "should not create user job result when enqueued" do
      job = Examples::SuccessfulUserManagedJob.new

      expect(UserJobResult).not_to receive(:create_default!)
      job.enqueue!
      expect(job.instance_variable_get(:@user_job_result_id)).to be_nil
    end

    it "should successfully complete job" do
      enqueued_job = Examples::UserManagedJobWithProgress.new.enqueue!

      expect do
        run_enqueued_job(enqueued_job)
      end.to change { Delayed::Job.count }.by(-1)
    end

    it "should fail with expected exception" do
      enqueued_job = Examples::UnsuccessfulUserManagedJob.new.enqueue!
      run_enqueued_job(enqueued_job)

      expect(enqueued_job.last_error).to include("Something went wrong during job execution")
    end
  end

  it "should use custom job name if set" do
    job = Examples::SuccessfulUserManagedJob.new
    job.enqueue!
    user_job_result = job.user_job_result
    expect(user_job_result.name).to eql("Custom job name")
  end

  it "should use class name as job name if custom name is not set" do
    job = Examples::UnsuccessfulUserManagedJob.new
    job.enqueue!
    user_job_result = job.user_job_result
    expect(user_job_result.name).to eql("Examples::UnsuccessfulUserManagedJob")
  end
end
