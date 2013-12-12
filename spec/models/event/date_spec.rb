# encoding: utf-8

#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

# == Schema Information
#
# Table name: event_dates
#
#  id        :integer          not null, primary key
#  event_id  :integer          not null
#  label     :string(255)
#  start_at  :datetime
#  finish_at :datetime
#  location  :string(255)
#

require 'spec_helper'

describe Event::Date do

  let(:event) { events(:top_course) }

  it 'should only store date when no time is given' do
    date1 = '12.12.2012'
    date2 = '13.12.2012'
    event_date = event.dates.new(label: 'foobar')
    event_date.start_at_date = date1
    event_date.finish_at_date = date2

    event_date.should be_valid
    event_date.start_at.should == date1.to_date.to_time
    event_date.finish_at.should == date2.to_date.to_time
  end

  it 'should store short format date' do
    date1 = '1.2.98'
    date2 = '11.12.01'
    event_date = event.dates.new(label: 'foobar')
    event_date.start_at_date = date1
    event_date.finish_at_date = date2

    event_date.should be_valid
    event_date.start_at.should == Time.zone.local(1998, 2, 1)
    event_date.finish_at.should == Time.zone.local(2001, 12, 11)
  end

  it 'should have date and time when hours and min are given' do
    date1 = Time.zone.local(2012, 12, 12).to_date
    hours = 18
    min = 10
    event_date = event.dates.new(label: 'foobar')
    event_date.start_at_date = date1
    event_date.start_at_hour = hours
    event_date.start_at_min = min

    event_date.should be_valid
    event_date.start_at.should == Time.zone.local(2012, 12, 12, 18, 10)
    event_date.start_at_hour.should == 18
    event_date.start_at_min.should == 10
  end

  it 'should get hours,mins and date seperately' do
    date = Time.zone.local(2012, 12, 12, 18, 10)
    event_date = event.dates.new(label: 'foobar')
    # start_at
    event_date.start_at = date

    event_date.should be_valid
    event_date.start_at_date.should == date.to_date
    event_date.start_at_hour.should == 18
    event_date.start_at_min.should == 10
    # finish_at
    event_date.finish_at = date

    event_date.should be_valid
    event_date.finish_at_date.should == date.to_date
    event_date.finish_at_hour.should == 18
    event_date.finish_at_min.should == 10
  end

  it 'should update hours,mins when a date was stored previously' do
    date = Time.zone.local(2012, 12, 12).to_date
    event_date = event.dates.new(label: 'foobar')
    # set start_at date
    event_date.start_at_date = date
    event_date.should be_valid

    # update time
    event_date.start_at_hour = 18
    event_date.start_at_min = 10
    event_date.should be_valid

    event_date.start_at.should == Time.zone.local(2012, 12, 12, 18, 10)
  end

  it 'should remove date that was stored previously' do
    date = Time.zone.local(2012, 12, 12).to_date
    event_date = event.dates.new(label: 'foobar')
    # set start_at date
    event_date.start_at_date = date
    event_date.should be_valid
    event_date.start_at.should == date.to_time

    # update time
    event_date.start_at_date = ''
    event_date.start_at_hour = 18
    event_date.start_at_min = 10
    event_date.should_not be_valid

    event_date.start_at.should be_nil
  end

  it 'is invalid on partial date input' do
    date = event.dates.new(label: 'foobar')
    date.start_at_date = '15.12'
    date.should_not be_valid
    date.should have(2).errors_on(:start_at)
  end

  it 'is invalid on plain numbers input' do
    date = event.dates.new(label: 'foobar')
    date.start_at_date = '77'
    date.should_not be_valid
    date.should have(2).errors_on(:start_at)
  end
end
