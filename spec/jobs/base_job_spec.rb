
require 'spec_helper'

describe BaseJob do

  it 'calls airbrake if an exception occurs' do
    BaseJob.any_instance.stub(:perform).and_raise('error')
    Airbrake.should receive(:notify).and_call_original
    job = BaseJob.new
    job.enqueue!
    dj = job.delayed_jobs.first
    Delayed::Worker.new.run(dj)
  end

end
