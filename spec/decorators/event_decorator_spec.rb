require 'spec_helper'

describe EventDecorator do

  let(:group) { groups(:top_group)}
  let(:event) { Fabricate(:event, group: group, kind: event_kinds(:slk) ) }
  subject { EventDecorator.new(event) }

  its(:label) { should eq "Scharleiterkurs<br /><span class=\"muted\">TopGroup</span>" }
  

  describe "#dates" do

    it "joins multiple dates" do
      add_date(start_at: parse("2002-01-01"))
      add_date(start_at: parse("2002-01-01"))
      subject.dates_info.should eq "01.01.2002<br />01.01.2002"
    end
   
    context "date objects"  do
      it "start_at only" do
        add_date(start_at: parse("2002-01-01"))
        subject.dates_info.should eq "01.01.2002"
      end

      it "finish_at only" do
        add_date(finish_at: parse("2002-01-01"))
        subject.dates_info.should eq  "01.01.2002"

      end

      it "start and finish" do
        add_date(start_at: parse("2002-01-01"),finish_at: parse("2002-01-13"))
        subject.dates_info.should eq "01.01.2002 - 13.01.2002"
      end

      it "start and finish on same day" do
        add_date(start_at: parse("2002-01-01"),finish_at: parse("2002-01-01"))
        subject.dates_info.should eq "01.01.2002"
      end
    end

    context "time objects" do
      it "start_at only" do
        add_date(start_at: parse("2002-01-01 13:30"))
        subject.dates_info.should eq "01.01.2002"
      end
      it "finish_at only" do
        add_date(finish_at: parse("2002-01-01 13:30"))
        subject.dates_info.should eq  "01.01.2002"
      end

      it "start and finish" do
        add_date(start_at: parse("2002-01-01 13:30"),finish_at: parse("2002-01-13 15:30"))
        subject.dates_info.should eq "01.01.2002 - 13.01.2002"
      end

      it "start and finish on same day, start time" do
        add_date(start_at: parse("2002-01-01 13:30"),finish_at: parse("2002-01-01"))
        subject.dates_info.should eq "01.01.2002 13:30"
      end

      it "start and finish on same day, finish time" do
        add_date(start_at: parse("2002-01-01 13:30"),finish_at: parse("2002-01-01 13:30"))
        subject.dates_info.should eq "01.01.2002 13:30"
      end

      it "start and finish on same day, both times" do
        add_date(start_at: parse("2002-01-01 13:30"),finish_at: parse("2002-01-01 15:30"))
        subject.dates_info.should eq "01.01.2002 13:30 - 15:30"
      end
    end

    
  end
  def parse(str)
    Time.zone.parse(str)
  end
  def add_date(date)
    event.dates.build(date)
    event.save
  end

end
