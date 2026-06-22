#  Copyright (c) 2012-2026, Puzzle ITC. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "spec_helper"

describe GracefulTermination do
  include DelayedJobSpecHelper

  let(:job) { Test::GracefullyTerminatableJob.new }

  it "should raise signal exception when signal is present while checking terminated" do
    job.should_terminate_with_signal!("TERM")

    expect(Rails.logger).to receive(:debug).with("Before check_terminated!")
    expect(Rails.logger).not_to receive(:debug).with("After check_terminated!")

    delayed_job = enqueue_and_run_job(job)

    expect(delayed_job.last_error).to match("SIGTERM")
  end

  it "should not raise signal exception when signal is not present while checking terminated" do
    expect(Rails.logger).to receive(:debug).with("Before check_terminated!")
    expect(Rails.logger).to receive(:debug).with("After check_terminated!")

    enqueued_job = job.enqueue!

    expect { run_enqueued_job(enqueued_job) }.to change { Delayed::Job.count }.by(-1)
  end
end
