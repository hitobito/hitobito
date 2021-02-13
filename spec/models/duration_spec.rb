# encoding: utf-8

#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "spec_helper"
describe Duration do
  describe "#dates" do
    subject { @duration.to_s }

    context "date objects"  do
      it "start_at only" do
        create_duration(start_at: "2002-01-01")
        is_expected.to eq "01.01.2002"
      end

      it "finish_at only" do
        create_duration(finish_at: "2002-01-01")
        is_expected.to eq "01.01.2002"
      end

      it "start and finish" do
        create_duration(start_at: "2002-01-01", finish_at: "2002-01-13")
        is_expected.to eq "01.01.2002 - 13.01.2002"
      end

      it "start and finish on same day" do
        create_duration(start_at: "2002-01-01", finish_at: "2002-01-01")
        is_expected.to eq "01.01.2002"
      end

      it "works with regular dates as well" do
        @duration = Duration.new(Date.new(2010, 10, 9), Date.new(2010, 10, 12))
        is_expected.to eq "09.10.2010 - 12.10.2010"
      end
    end

    context "time objects" do
      it "start_at only" do
        create_duration(start_at: "2002-01-01 13:30")
        is_expected.to eq "01.01.2002 13:30"
      end
      it "finish_at only" do
        create_duration(finish_at: "2002-01-01 13:30")
        is_expected.to eq  "01.01.2002 13:30"
      end

      it "start and finish" do
        create_duration(start_at: "2002-01-01 13:30", finish_at: "2002-01-13 15:30")
        is_expected.to eq "01.01.2002 13:30 - 13.01.2002 15:30"
      end

      it "start and finish on same day, start time" do
        create_duration(start_at: "2002-01-01", finish_at: "2002-01-01 13:30")
        is_expected.to eq "01.01.2002 00:00 - 13:30"
      end

      it "start and finish on same day, finish time" do
        create_duration(start_at: "2002-01-01 13:30", finish_at: "2002-01-01 13:30")
        is_expected.to eq "01.01.2002 13:30"
      end

      it "start and finish on same day, both times" do
        create_duration(start_at: "2002-01-01 13:30", finish_at: "2002-01-01 15:30")
        is_expected.to eq "01.01.2002 13:30 - 15:30"
      end
    end
  end

  context "#active?" do
    subject { @duration }

    context "by date" do
      it "today is active" do
        @duration = Duration.new(Time.zone.today, Time.zone.today)
        is_expected.to be_active
      end

      it "until today is active" do
        @duration = Duration.new(Time.zone.today - 10.days, Time.zone.today)
        is_expected.to be_active
      end

      it "from today is active" do
        @duration = Duration.new(Time.zone.today, Time.zone.today + 10.days)
        is_expected.to be_active
      end

      it "from tomorrow is not active" do
        @duration = Duration.new(Time.zone.today + 1.day, Time.zone.today + 10.days)
        is_expected.not_to be_active
      end

      it "until yesterday is not active" do
        @duration = Duration.new(Time.zone.today - 10.days, Time.zone.today - 1.day)
        is_expected.not_to be_active
      end
    end

    context "by Time" do
      it "now is active" do
        @duration = Duration.new(Time.zone.now - 1.minute, Time.zone.now + 1.minute)
        is_expected.to be_active
      end

      it "until now is active" do
        @duration = Duration.new(Time.zone.now - 10.minute, Time.zone.now + 1.minute)
        is_expected.to be_active
      end

      it "from now is active" do
        @duration = Duration.new(Time.zone.now - 1.minute, Time.zone.now + 10.minute)
        is_expected.to be_active
      end

      it "from in a minute is not active" do
        @duration = Duration.new(Time.zone.now + 1.minute, Time.zone.now + 10.minute)
        is_expected.not_to be_active
      end

      it "until a minute is not active" do
        @duration = Duration.new(Time.zone.now - 10.minute, Time.zone.now - 1.minute)
        is_expected.not_to be_active
      end
    end
  end

  def parse(str)
    Time.zone.parse(str) if str.present?
  end
  def create_duration(date)
    @duration = Duration.new(parse(date[:start_at]), parse(date[:finish_at]))
  end

end
