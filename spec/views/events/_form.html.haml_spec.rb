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
    let(:contact_attrs) { dom.find("#contact_attrs fieldset") }

    it "has range of attributes" do
      render
      expect(contact_attrs).to have_css(".row:nth-of-type(1) > label", text: "Haupt-E-Mail")
      expect(contact_attrs).to have_css(".row:nth-of-type(2) > label", text: "Vorname")
      expect(contact_attrs).to have_css(".row:nth-of-type(3) > label", text: "Nachname")
      expect(contact_attrs).to have_css(".row:nth-of-type(4) > label", text: "Übername")
    end

    describe "mandatory attribute" do
      let(:email) { contact_attrs.find(".row:nth-of-type(1)") }

      it "renders single disabled obligatory radio button" do
        render
        expect(email).to have_css "label", text: "Haupt-E-Mail"
        expect(email).to have_css "input[type=radio][disabled]", count: 1
        expect(email).to have_text "Obligatorisch"
      end
    end

    (Event::ParticipationContactData.contact_attrs - Event::ParticipationContactData.mandatory_contact_attrs).each_with_index do |attribute, index|
      describe "configurable attribute" do
        let(:attr_field) { contact_attrs.find(".row:nth-of-type(#{index + 4})") }

        it "renders three radio buttons" do
          render
          expect(attr_field).to have_css "input[type=radio]", count: 3
          expect(attr_field).to have_unchecked_field "Obligatorisch"
          expect(attr_field).to have_checked_field "Optional"
          expect(attr_field).to have_unchecked_field "Nicht anzeigen"
        end

        it "renders radio buttons with correct id and name attributes" do
          render
          expect(attr_field.find_field("Optional").native.attributes["id"].value).to eq "event_contact_attrs_#{attribute}_optional"
          expect(attr_field.find_field("Optional").native.attributes["name"].value).to eq "event[contact_attrs][#{attribute}]"
          expect(attr_field.find_field("Obligatorisch").native.attributes["id"].value).to eq "event_contact_attrs_#{attribute}_required"
          expect(attr_field.find_field("Obligatorisch").native.attributes["name"].value).to eq "event[contact_attrs][#{attribute}]"
        end

        it "sets radio value according to value set on event" do
          allow(event).to receive(:hidden_contact_attrs).and_return([attribute.to_s])
          render
          expect(attr_field).to have_unchecked_field "Optional"
          expect(attr_field).to have_checked_field "Nicht anzeigen"
        end
      end
    end
  end

  describe "checkboxes" do
    let(:additional_emails) { dom.find("#contact_attrs .row:nth-of-type(17)") }

    it "does use set name attribute on associations" do
      render
      expect(additional_emails).to have_css "input[type=hidden]", visible: :all, count: 1
      expect(additional_emails).to have_css "input[type=checkbox]", count: 1
      expect(additional_emails).to have_css "label", text: "Weitere E-Mails"
    end

    it "does render radio buttons with correct id and name attributes" do
      render
      expect(additional_emails.find("input[type=hidden]", visible: :all).native.attributes["name"].value).to eq "event[contact_attrs][additional_emails]"
      expect(additional_emails.find("input[type=hidden]", visible: :all).native.attributes["value"].value).to eq "0"
      expect(additional_emails.find_field("Nicht anzeigen").native.attributes["id"].value).to eq "event_contact_attrs_additional_emails"
      expect(additional_emails).to have_unchecked_field "Nicht anzeigen"
    end

    it "does check field if value is checked on event" do
      allow(event).to receive(:hidden_contact_attrs).and_return(["additional_emails"])
      render
      expect(additional_emails).to have_checked_field "Nicht anzeigen"
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
