require 'spec_helper'
describe Duration do
  subject { @duration.to_s }
  describe "#dates" do
   
    context "date objects"  do
      it "start_at only" do
        add_date(start_at: parse("2002-01-01"))
        should eq "01.01.2002"
      end

      it "finish_at only" do
        add_date(finish_at: parse("2002-01-01"))
        should eq "01.01.2002"
      end

      it "start and finish" do
        add_date(start_at: parse("2002-01-01"),finish_at: parse("2002-01-13"))
        should eq "01.01.2002 - 13.01.2002"
      end

      it "start and finish on same day" do
        add_date(start_at: parse("2002-01-01"),finish_at: parse("2002-01-01"))
        should eq "01.01.2002"
      end
    end

    context "time objects" do
      it "start_at only" do
        add_date(start_at: parse("2002-01-01 13:30"))
        should eq "01.01.2002"
      end
      it "finish_at only" do
        add_date(finish_at: parse("2002-01-01 13:30"))
        should eq  "01.01.2002"
      end

      it "start and finish" do
        add_date(start_at: parse("2002-01-01 13:30"),finish_at: parse("2002-01-13 15:30"))
        should eq "01.01.2002 - 13.01.2002"
      end

      it "start and finish on same day, start time" do
        add_date(start_at: parse("2002-01-01 13:30"),finish_at: parse("2002-01-01"))
        should eq "01.01.2002 13:30"
      end

      it "start and finish on same day, finish time" do
        add_date(start_at: parse("2002-01-01 13:30"),finish_at: parse("2002-01-01 13:30"))
        should eq "01.01.2002 13:30"
      end

      it "start and finish on same day, both times" do
        add_date(start_at: parse("2002-01-01 13:30"),finish_at: parse("2002-01-01 15:30"))
        should eq "01.01.2002 13:30 - 15:30"
      end
    end

  end
  
  def parse(str)
    Time.zone.parse(str)
  end
  def add_date(date)
    @duration = Duration.new(date[:start_at], date[:finish_at])
  end

end

