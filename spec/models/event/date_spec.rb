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
#  label     :string
#  start_at  :datetime
#  finish_at :datetime
#  location  :string
#

require "spec_helper"

describe Event::Date do
  let(:event) { events(:top_course) }

  it "should only store date when no time is given" do
    date1 = "12.12.2012"
    date2 = "13.12.2012"
    event_date = event.dates.new(label: "foobar")
    event_date.start_at_date = date1
    event_date.finish_at_date = date2

    expect(event_date).to be_valid
    expect(event_date.start_at).to eq(Time.zone.local(2012, 12, 12))
    expect(event_date.finish_at).to eq(Time.zone.local(2012, 12, 13))
  end

  it "should store short format date" do
    date1 = "1.2.98"
    date2 = "11.12.01"
    event_date = event.dates.new(label: "foobar")
    event_date.start_at_date = date1
    event_date.finish_at_date = date2

    expect(event_date).to be_valid
    expect(event_date.start_at).to eq(Time.zone.local(1998, 2, 1))
    expect(event_date.finish_at).to eq(Time.zone.local(2001, 12, 11))
  end

  it "should have date and time when hours and min are given" do
    date1 = Time.zone.local(2012, 12, 12).to_date
    hours = 18
    min = 10
    event_date = event.dates.new(label: "foobar")
    event_date.start_at_date = date1
    event_date.start_at_hour = hours
    event_date.start_at_min = min

    expect(event_date).to be_valid
    expect(event_date.start_at).to eq(Time.zone.local(2012, 12, 12, 18, 10))
    expect(event_date.start_at_hour).to eq(18)
    expect(event_date.start_at_min).to eq(10)
  end

  it "should get hours,mins and date seperately" do
    date = Time.zone.local(2012, 12, 12, 18, 10)
    event_date = event.dates.new(label: "foobar")
    # start_at
    event_date.start_at = date

    expect(event_date).to be_valid
    expect(event_date.start_at_date).to eq(date.to_date)
    expect(event_date.start_at_hour).to eq(18)
    expect(event_date.start_at_min).to eq(10)
    # finish_at
    event_date.finish_at = date

    expect(event_date).to be_valid
    expect(event_date.finish_at_date).to eq(date.to_date)
    expect(event_date.finish_at_hour).to eq(18)
    expect(event_date.finish_at_min).to eq(10)
  end

  it "should update hours,mins when a date was stored previously" do
    date = Time.zone.local(2012, 12, 12).to_date
    event_date = event.dates.new(label: "foobar")
    # set start_at date
    event_date.start_at_date = date
    expect(event_date).to be_valid

    # update time
    event_date.start_at_hour = 18
    event_date.start_at_min = 10
    expect(event_date).to be_valid

    expect(event_date.start_at).to eq(Time.zone.local(2012, 12, 12, 18, 10))
  end

  it "should remove date that was stored previously" do
    date = Time.zone.local(2012, 12, 12).to_date
    event_date = event.dates.new(label: "foobar")
    # set start_at date
    event_date.start_at_date = date
    expect(event_date).to be_valid
    expect(event_date.start_at).to eq(Time.zone.local(2012, 12, 12))

    # update time
    event_date.start_at_date = ""
    event_date.start_at_hour = 18
    event_date.start_at_min = 10
    expect(event_date).not_to be_valid

    expect(event_date.start_at).to be_nil
  end

  it "is invalid on partial date input" do
    date = event.dates.new(label: "foobar")
    date.start_at_date = "15.12"
    expect(date).not_to be_valid
    expect(date).to have(2).errors_on(:start_at)
  end

  it "is invalid on plain numbers input" do
    date = event.dates.new(label: "foobar")
    date.start_at_date = "77"
    expect(date).not_to be_valid
    expect(date).to have(2).errors_on(:start_at)
  end
end
