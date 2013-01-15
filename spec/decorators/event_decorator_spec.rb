require 'spec_helper'

describe EventDecorator, :draper_with_helpers do
  include Rails.application.routes.url_helpers


  let(:event) { ev = events(:top_course); ev.dates.clear; ev }
  subject { EventDecorator.new(event) }

  its(:labeled_link) { should =~ /SLK  Top/ }
  its(:labeled_link) { should =~ %r{<a href="/groups/#{event.group_ids.first}/events/#{event.id}">} }

  context "typeahead label" do
    subject { EventDecorator.new(event).as_typeahead[:label] }
    it { should eq "#{event} (#{event.groups.first})" }

    context "multiple groups are joined and truncated" do
      before { event.groups += [groups(:top_group), groups(:bottom_layer_one), groups(:bottom_group_one_one),
                                groups(:bottom_layer_two), groups(:bottom_group_two_one)] }

      it { should eq "#{event} (Top, TopGroup, Bottom One...)" }
    end
  end

  describe "#dates" do

    it "joins multiple dates" do
      add_date(start_at: "2002-01-01")
      add_date(start_at: "2002-01-01")
      subject.dates_info.should eq "01.01.2002<br />01.01.2002"
    end

    context "date objects"  do
      it "start_at only" do
        add_date(start_at: "2002-01-01")
        subject.dates_info.should eq "01.01.2002"
      end

      it "start and finish" do
        add_date(start_at: "2002-01-01", finish_at: "2002-01-13")
        subject.dates_info.should eq "01.01.2002 - 13.01.2002"
      end

      it "start and finish on same day" do
        add_date(start_at: "2002-01-01", finish_at: "2002-01-01")
        subject.dates_info.should eq "01.01.2002"
      end
    end

    context "time objects" do
      it "start_at only" do
        add_date(start_at: "2002-01-01 13:30")
        subject.dates_info.should eq "01.01.2002 13:30"
      end

      it "start and finish" do
        add_date(start_at: "2002-01-01 13:30", finish_at: "2002-01-13 15:30")
        subject.dates_info.should eq "01.01.2002 13:30 - 13.01.2002 15:30"
      end

      it "start and finish on same day, start time" do
        add_date(start_at: "2002-01-01", finish_at: "2002-01-01 13:30")
        subject.dates_info.should eq "01.01.2002 00:00 - 13:30"
      end

      it "start and finish on same day, finish time" do
        add_date(start_at: "2002-01-01 13:30", finish_at: "2002-01-01 13:30")
        subject.dates_info.should eq "01.01.2002 13:30"
      end

      it "start and finish on same day, both times" do
        add_date(start_at: "2002-01-01 13:30", finish_at: "2002-01-01 15:30")
        subject.dates_info.should eq "01.01.2002 13:30 - 15:30"
      end
    end

  end

  context "event kind info" do

    let(:kind) { Fabricate(:event_kind, minimum_age: 99, qualification_kinds: [qualification_kinds(:sl)]) }
    let(:course) { Fabricate(:course, kind: kind) }
    subject { EventDecorator.new(course) }

    it "should return minimum age and required qualification kinds" do
      subject.kind_info.should =~ /Super Lead/
      subject.kind_info.should =~ /99/
    end
  end

  def parse(str)
    Time.zone.parse(str)
  end

  def add_date(date)
    %w[:start_at, :finish_at].each do |key|
      date[key] = parse(date[key]) if date.key?(key)
    end
    event.dates.build(date)
    event.save!
  end
end
