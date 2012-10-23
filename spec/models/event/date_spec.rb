# == Schema Information
#
# Table name: event_dates
#
#  id        :integer          not null, primary key
#  event_id  :integer          not null
#  label     :string(255)
#  start_at  :datetime
#  finish_at :datetime
#

require 'spec_helper'

describe Event::Date do

  it 'should only store date when no time is given' do
    date1 = '12.12.2012'
    date2 = '13.12.2012'
    event_date = Event::Date.new(label: 'foobar')
    event_date.event = Fabricate(:event, group: groups(:top_group))
    event_date.start_at_date = date1
    event_date.finish_at_date = date2

    event_date.valid?.should be true
    event_date.start_at.should == date1.to_date.to_time
    event_date.finish_at.should == date2.to_date.to_time
  end

  it 'should have date and time when hours and min are given' do
    date1 = Time.zone.local(2012,12,12).to_date
    hours = 18
    min = 10
    event_date = Event::Date.new(label: 'foobar')
    event_date.event = Fabricate(:event, group: groups(:top_group))
    event_date.start_at_date = date1
    event_date.start_at_h = hours
    event_date.start_at_min = min

    event_date.valid?.should be true
    event_date.start_at.should == Time.zone.local(2012,12,12,18,10)
    event_date.start_at_h.should == 18
    event_date.start_at_min.should == 10
  end

  it 'should get hours,mins and date seperately' do
    date = Time.zone.local(2012,12,12,18,10)
    event_date = Event::Date.new(label: 'foobar')
    event_date.event = Fabricate(:event, group: groups(:top_group))
    # start_at
    event_date.start_at = date

    event_date.valid?.should be true
    event_date.start_at_date.should == date.to_date
    event_date.start_at_h.should == 18
    event_date.start_at_min.should == 10
    # finish_at
    event_date.finish_at = date

    event_date.valid?.should be true
    event_date.finish_at_date.should == date.to_date
    event_date.finish_at_h.should == 18
    event_date.finish_at_min.should == 10
  end

end
