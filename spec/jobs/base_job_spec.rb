require "spec_helper"

describe BaseJob do
  it "calls airbrake if an exception occurs" do
    allow_any_instance_of(BaseJob).to receive(:perform).and_raise("error")
    expect(Airbrake).to receive(:notify).and_call_original
    job = BaseJob.new
    job.enqueue!
    dj = job.delayed_jobs.first
    Delayed::Worker.new.run(dj)
  end
end
