# encoding: utf-8

#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "spec_helper"

describe RecurringJob do

  subject { RecurringJob.new }

  its(:interval) { should == 15.minutes }

  it "schedules job unless it exists" do
    now = Time.zone.now
    subject.schedule
    # second schedule does nothing
    subject.schedule

    expect(subject).to be_scheduled
    expect(subject.delayed_jobs.count).to eq(1)
    expect(subject.delayed_jobs.first.run_at).to be_within(1.second).of(now + 15.minutes)
  end

  it "is rescheduled after successfull run" do
    expect_any_instance_of(RecurringJob).to receive(:perform_internal)

    expect(subject).not_to be_scheduled

    now = Time.zone.now
    subject.enqueue!(run_at: now)
    expect(subject).to be_scheduled

    Delayed::Worker.new.work_off

    expect(subject).to be_scheduled
    expect(subject.delayed_jobs.count).to eq(1)
    expect(subject.delayed_jobs.first.run_at).to be_within(1.second).of(now + 15.minutes)
  end

  it "is rescheduled after failed run" do
    expect_any_instance_of(RecurringJob).to receive(:perform_internal).and_raise("error!")
    expect_any_instance_of(RecurringJob).to receive(:error).with(anything, an_instance_of(RuntimeError))

    now = Time.zone.now
    subject.enqueue!(run_at: now)

    Delayed::Worker.new.work_off

    expect(subject).to be_scheduled
    expect(subject.delayed_jobs.count).to eq(1)
    expect(subject.delayed_jobs.first.run_at).to be_within(1.second).of(now + 15.minutes)
  end

  it "is rescheduled after worker pause" do
    now = Time.zone.now
    subject.enqueue!(run_at: 1.month.ago)
    expect(subject).to be_scheduled

    Delayed::Worker.new.work_off

    expect(subject).to be_scheduled
    expect(subject.delayed_jobs.count).to eq(1)
    expect(subject.delayed_jobs.first.run_at).to be_within(1.second).of(now + 15.minutes)
  end

  it "reschedules only one job" do
    expect(subject).not_to be_scheduled

    now = Time.zone.now
    subject.enqueue!(run_at: now)
    expect(subject).to be_scheduled
    subject.enqueue!(run_at: now)
    subject.enqueue!(run_at: now)

    Delayed::Worker.new.work_off

    expect(subject).to be_scheduled
    expect(subject.delayed_jobs.count).to eq(1)
    expect(subject.delayed_jobs.first.run_at).to be_within(1.second).of(now + 15.minutes)
  end
end
