# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of hitobito and licensed under the
#  Affero General Public License version 3 or later. See the COPYING file at the top-level directory
#  or at https://github.com/hitobito/hitobito.

require "spec_helper"

describe "events/_form.html.haml" do
  let(:user) { people(:top_leader) }
  let(:event) { events(:top_event) }
  let(:group) { event.groups.first }
  let(:dom) { Capybara::Node::Simple.new(raw(rendered)) }

  before do
    allow(view).to receive_messages(path_args: [group, event])
    allow(view).to receive_messages(entry: event.decorate)
    allow(view).to receive_messages(current_user: user, model_class: event.class)
    allow(controller).to receive_messages(current_user: user)
    assign(:kinds, [])
    assign(:event, event)
    assign(:group, group)
  end

  describe "contact_attrs" do
    describe "nickname" do
      it "does render three radio buttons" do
        render
        fields = dom.find("#contact_attrs div:nth-of-type(2)")
        expect(fields).to have_css "input[type=radio]", count: 3
        expect(fields).to have_css "label", text: "Übername"
        expect(fields).to have_unchecked_field "Obligatorisch"
        expect(fields).to have_checked_field "Optional"
        expect(fields).to have_unchecked_field "Nicht anzeigen"
      end

      it "does set radio if value is set on event" do
        allow(event).to receive(:hidden_contact_attrs).and_return(["nickname"])
        render
        fields = dom.find("#contact_attrs div:nth-of-type(2)")
        expect(fields).to have_unchecked_field "Optional"
        expect(fields).to have_checked_field "Nicht anzeigen"
      end

      it "does render radio buttons with correct id and name attributes" do
        render
        fields = dom.find("#contact_attrs div:nth-of-type(2)")
        expect(fields.find_field("Optional").native.attributes["id"].value).to eq "event_contact_attrs_nickname_optional"
        expect(fields.find_field("Optional").native.attributes["name"].value).to eq "event[contact_attrs][nickname]"
        expect(fields.find_field("Obligatorisch").native.attributes["id"].value).to eq "event_contact_attrs_nickname_required"
        expect(fields.find_field("Obligatorisch").native.attributes["name"].value).to eq "event[contact_attrs][nickname]"
      end
    end
  end

  describe "checkboxes" do
    it "does use set name attribute on associations" do
      render
      fields = dom.find("#contact_attrs div:nth-of-type(3)")
      expect(fields).to have_css "input[type=hidden]", visible: :all, count: 1
      expect(fields).to have_css "input[type=checkbox]", count: 1
      expect(fields).to have_css "label", text: "Weitere E-Mails"
    end

    it "does render radio buttons with correct id and name attributes" do
      render
      fields = dom.find("#contact_attrs div:nth-of-type(3)")
      expect(fields.find("input[type=hidden]", visible: :all).native.attributes["name"].value).to eq "event[contact_attrs][additional_emails]"
      expect(fields.find("input[type=hidden]", visible: :all).native.attributes["value"].value).to eq "0"
      expect(fields.find_field("Nicht anzeigen").native.attributes["id"].value).to eq "event_contact_attrs_additional_emails"
      expect(fields).to have_unchecked_field "Nicht anzeigen"
    end

    it "does check field if value is checked on event" do
      allow(event).to receive(:hidden_contact_attrs).and_return(["additional_emails"])
      render
      fields = dom.find("#contact_attrs div:nth-of-type(3)")
      expect(fields).to have_checked_field "Nicht anzeigen"
    end
  end

  context "course" do
    let(:event) { events(:top_course) }

    [:hidden_contact_attrs, :required_contact_attrs].each do |attr|
      it "renders Kontaktangaben tab when #{attr} is used" do
        allow(Event::Course).to receive(:used_attributes).and_return([attr])
        render
        expect(dom).to have_link "Kontaktangaben"
      end
    end
  end
end
