# frozen_string_literal: true

#  Copyright (c) 2026, Schweizer Alpen-Club. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "spec_helper"

describe Dropdown::Event::QuestionAdd do
  include FormatHelper
  include LayoutHelper
  include UtilityHelper

  let(:group) { groups(:top_layer) }
  let(:other_layer) { groups(:bottom_layer_one) }
  let(:event) { Fabricate(:course, groups: [group]) }
  let(:dropdown) { described_class.new(self, group, event) }

  subject { Capybara.string(dropdown.to_s) }

  def create_template(question_text, group: self.group, event_type: "Event::Course", default: false, admin: false,
    inherit: false)
    Event::QuestionTemplate.create!(
      group: group,
      event_type: event_type,
      default: default,
      inherit: inherit,
      question: Event::Question::Default.create!(question: question_text, admin: admin)
    )
  end

  before { Event::QuestionTemplate.delete_all }

  context "buttons" do
    before { create_template("Some template") }

    it "renders the main button with the add action" do
      is_expected.to have_css(
        "a[data-action='events--question-template-nested-form#add']",
        text: "Eintrag hinzufügen"
      )
    end

    it "renders template items with the addFromTemplate action" do
      is_expected.to have_css(
        "a[data-action='events--question-template-nested-form#addFromTemplate']",
        text: "Some template"
      )
    end
  end

  context "hierarchy filtering" do
    before do
      create_template("In hierarchy")
      create_template("Outside hierarchy", group: other_layer)
    end

    it "renders templates within the group hierarchy" do
      is_expected.to have_link("In hierarchy")
    end

    it "does not render templates outside the group hierarchy" do
      is_expected.not_to have_link("Outside hierarchy")
    end
  end

  context "event type filtering" do
    before do
      create_template("Matching event type")
      create_template("Non-matching event type", event_type: "Event::Camp")
    end

    it "renders templates with matching event type" do
      is_expected.to have_link("Matching event type")
    end

    it "does not render templates with non-matching event type" do
      is_expected.not_to have_link("Non-matching event type")
    end
  end

  context "default flag" do
    before do
      create_template("Default template", default: true)
      create_template("Non-default template", default: false)
    end

    it "renders templates regardless of default flag" do
      is_expected.to have_link("Default template")
      is_expected.to have_link("Non-default template")
    end
  end

  context "admin flag" do
    let(:admin_dropdown) { described_class.new(self, group, event, admin: true) }

    before do
      create_template("Application question")
      create_template("Admin question", admin: true)
    end

    it "renders only application questions by default" do
      subject = Capybara.string(dropdown.to_s)
      expect(subject).to have_link("Application question")
      expect(subject).not_to have_link("Admin question")
    end

    it "renders only admin questions when admin: true" do
      subject = Capybara.string(admin_dropdown.to_s)
      expect(subject).to have_link("Admin question")
      expect(subject).not_to have_link("Application question")
    end
  end
end
