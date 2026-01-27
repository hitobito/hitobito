#  Copyright (c) 2014, SAC-CAS. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "spec_helper"

describe PeopleHelper, type: :helper do
  describe "#oneline_address" do
    it "formats the address" do
      @person = people(:top_leader)
      message = messages(:simple)
      expect(oneline_address(message)).to eq("Hauptstrasse 1, 3023 Musterstadt")
    end
  end

  describe "#upcoming_events_title" do
    before do
      @virtual_path = "/people/attrs"
      allow(self).to receive(:icon).and_return("")
    end

    let(:entry) { double(id: 1) }
    let(:current_user) { double(id: 2) }
    let(:icon) { double("icon") }

    it "without events_class argument returns default title" do
      event_text = Event.model_name.human(count: :many)
      expect(upcoming_events_title)
        .to include(I18n.t("people.attrs.events", event_type_label: event_text))
    end

    it "with events_class argument returns title with class name" do
      events_class = Event::Course
      event_text = events_class.model_name.human(count: :many)
      expect(upcoming_events_title(events_class))
        .to eq I18n.t("people.attrs.events", event_type_label: event_text)
    end

    it "includes calendar link when current_user is the person" do
      allow(self).to receive(:current_user).and_return(entry)
      title = Capybara::Node::Simple.new(upcoming_events_title)
      expect(title).to have_link("In Kalender integrieren", href: event_feed_path)
    end
  end
end
