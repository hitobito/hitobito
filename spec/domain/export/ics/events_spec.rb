# encoding: utf-8

#  Copyright (c) 2012-2020, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "spec_helper"

describe Export::Ics::Events do
  let(:event) { events(:top_course) }
  let(:event_date) { event.dates.first }
  let(:export) { described_class.new }
  let(:ical_date_klass) { Icalendar::Values::Date }
  let(:ical_datetime_klass) { Icalendar::Values::DateTime }

  before do
    allow(ENV).to receive(:[]).with("RAILS_HOST_NAME").and_call_original
    allow(ENV).to receive(:[]).with("RAILS_HOST_NAME").and_return("hitobito.example.com")
  end

  describe "#generate_ical_from_event_dates" do
    subject(:ical_events) { export.generate_ical_from_event_dates(event) }

    it "contains the event dates" do
      is_expected.to all(be_a(Icalendar::Event))
      expect(ical_events.count).to eq(event.dates.count)
    end

    it "does not fail if contact is set" do
      event.update(contact: people(:top_leader))

      people(:top_leader).phone_numbers.create!(label: "showme", number: "+41 44 123 45 67", public: true)
      people(:top_leader).phone_numbers.create!(label: "notme", number: "+41 77 987 65 43", public: false)

      is_expected.to all(be_a(Icalendar::Event))
      expect(subject.first.contact.first.value).to eq "Top Leader"
      expect(subject.first.description.value).to include "Top Leader"
      expect(subject.first.description.value).to include "top_leader@example.com"
      expect(subject.first.description.value).to include "showme"
      expect(subject.first.description.value).not_to include "notme"
    end
  end

  describe "#event_description" do
    subject { export.event_description(event) }
    let(:contact) { people(:top_leader) }

    before do
      allow(event).to receive(:contact).and_return(contact)
    end

    it do
      is_expected.to include(event.description)
      is_expected.to include(contact.person_name)
      is_expected.to include(contact.email)
      url = Rails.application.routes.url_helpers.group_event_url(event.groups.first, event, host: ENV["RAILS_HOST_NAME"])
      is_expected.to include(url)
    end
  end

  describe "#generate_ical_from_event_date" do
    subject(:ical_event) { export.generate_ical_from_event_date(event_date, event) }

    context "with only a start date" do
      let(:event_date) do
        Event::Date.new(event: event, label: "Main part", start_at: Time.zone.local(2018, 5, 19), location: "testlocation")
      end

      it do
        expect(ical_event.dtstart).to be_a(ical_date_klass)
        expect(ical_event.dtstart.value_ical).to eq(event_date.start_at.strftime(ical_date_klass::FORMAT))
        expect(ical_event.dtend).to be nil
        expect(ical_event.summary.to_s).to eq("#{event.name}: #{event_date.label}")
        expect(ical_event.location.to_s).to eq(event_date.location)
      end
    end

    context "with a date with empty label" do
      let(:event_date) do
        Event::Date.new(event: event, start_at: Time.zone.local(2018, 5, 19), location: "testlocation")
      end

      it "omits the empty date label and colon" do
        expect(ical_event.summary.to_s).to eq("#{event.name}")
      end
    end

    context "with a start datetime and an end datetime" do
      let(:event_date) do
        Event::Date.new(
          event: event,
          start_at: Time.zone.local(2018, 5, 19, 12, 0),
          finish_at: Time.zone.local(2018, 5, 21, 16, 0)
        )
      end

      it do
        expect(ical_event.dtstart).to be_a(ical_datetime_klass)
        expect(ical_event.dtstart.value_ical).to eq("20180519T100000Z")
        expect(ical_event.dtend).to be_a(ical_datetime_klass)
        expect(ical_event.dtend.value_ical).to eq("20180521T140000Z")
      end
    end

    context "with an all-day event" do
      let(:event_date) do
        Event::Date.new(
          event: event,
          start_at: Time.zone.local(2018, 5, 19, 0, 0),
          finish_at: Time.zone.local(2018, 5, 21, 0, 0)
        )
      end

      it "should export the non-inclusive end date" do
        expect(ical_event.dtend.value_ical).to eq((event_date.finish_at + 1.day).strftime(ical_date_klass::FORMAT))
      end
    end
  end

  describe "#datetime_to_ical" do
    subject { export.datetime_to_ical(datetime) }

    context "with fullday event" do
      let(:datetime) { Time.zone.local(2018, 5, 19) }
      it { is_expected.to be_a(ical_date_klass) }
    end

    context "with timed event" do
      let(:datetime) { Time.zone.local(2018, 5, 19, 12, 15) }
      it { is_expected.to be_a(ical_datetime_klass) }
    end

    context "with nil" do
      let(:datetime) { nil }
      it { is_expected.to be nil }
    end
end

  describe "#generate" do
    subject(:ical_events) { export.generate([event, event]) }

    it do
      is_expected.to include("BEGIN:VCALENDAR")
      is_expected.to include("VERSION:2.0")
      is_expected.to include("BEGIN:VCALENDAR")
    end
  end
end
