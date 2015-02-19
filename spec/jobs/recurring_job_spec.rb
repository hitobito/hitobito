# encoding: utf-8

#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require 'spec_helper'

describe RecurringJob do

  subject { RecurringJob.new }

  its(:interval) { should == 15.minutes }

  it 'schedules job unless it exists' do
    now = Time.zone.now
    subject.schedule
    # second schedule does nothing
    subject.schedule

    subject.should be_scheduled
    subject.delayed_jobs.count.should == 1
    subject.delayed_jobs.first.run_at.should be_within(1.second).of(now + 15.minutes)
  end

  it 'is rescheduled after successfull run' do
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

  it 'is rescheduled after failed run' do
    RecurringJob.any_instance.should_receive(:perform_internal).and_raise('error!')
    RecurringJob.any_instance.should_receive(:error).with(anything, an_instance_of(RuntimeError))

    now = Time.zone.now
    subject.enqueue!(run_at: now)

    Delayed::Worker.new.work_off

    subject.should be_scheduled
    subject.delayed_jobs.count.should == 1
    subject.delayed_jobs.first.run_at.should be_within(1.second).of(now + 15.minutes)
  end

  it 'is rescheduled after worker pause' do
    RecurringJob.any_instance.should_receive(:perform_internal)

    now = Time.zone.now
    subject.enqueue!(run_at: 1.month.ago)
    subject.should be_scheduled

    Delayed::Worker.new.work_off

    subject.should be_scheduled
    subject.delayed_jobs.count.should == 1
    subject.delayed_jobs.first.run_at.should be_within(1.second).of(now + 15.minutes)
  end

  it 'reschedules only one job' do
    RecurringJob.any_instance.should_receive(:perform_internal)

    subject.should_not be_scheduled

    now = Time.zone.now
    subject.enqueue!(run_at: now)
    subject.should be_scheduled
    subject.enqueue!(run_at: now)
    subject.enqueue!(run_at: now)

    Delayed::Worker.new.work_off

    subject.should be_scheduled
    subject.delayed_jobs.count.should == 1
    subject.delayed_jobs.first.run_at.should be_within(1.second).of(now + 15.minutes)
  end
end
