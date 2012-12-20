require 'spec_helper'

describe RecurringJob do
  
  subject { RecurringJob.new }
  
  its(:interval) { should == 15.minutes }
  
  it "is rescheduled after successfull run" do
    RecurringJob.any_instance.should_receive(:perform_internal)
    
    subject.should_not be_scheduled
    
    now = Time.zone.now
    subject.enqueue!(run_at: now)
    subject.should be_scheduled

    Delayed::Worker.new.work_off
    
    subject.should be_scheduled
    subject.delayed_jobs.count.should == 1
    subject.delayed_jobs.first.run_at.should be_within(1.second).of(now + 15.minutes)
  end
    
  it "is rescheduled after failed run" do
    RecurringJob.any_instance.should_receive(:perform_internal).and_raise('error!')
    
    now = Time.zone.now
    subject.enqueue!(run_at: now)
    
    Delayed::Worker.new.work_off
    
    subject.should be_scheduled
    subject.delayed_jobs.count.should == 1
    subject.delayed_jobs.first.run_at.should be_within(1.second).of(now + 15.minutes)
  end
end
