# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

require "spec_helper"

describe Dropdown::Event::Participation::SendMail do
  include Rails.application.routes.url_helpers
  include FormatHelper
  include LayoutHelper
  include UtilityHelper

  let(:user) { people(:top_leader) }
  let(:event) { events(:top_event) }
  let(:group) { groups(:top_group) }
  let(:participation) do
    Event::Participation.create!(event: event, person: people(:bottom_member))
  end
  let(:dropdown) do
    described_class.new(self, event, group, participation)
  end

  subject { Capybara.string(dropdown.to_s) }

  def menu = subject.find(".btn-group > ul.dropdown-menu")

  context "without context" do
    before do
      CustomContent.create!(
        key: "event_application_confirmation",
        label: "Custom Content without context",
        body: ""
      )
    end

    it "renders custom content labels as dropdown options" do
      is_expected.to have_content "E-Mail senden"

      expect(menu).to have_link "Custom Content without context"
    end
  end

  context "with context" do
    before do
      CustomContent.create!(
        key: "event_application_confirmation",
        label: "Custom Content in context",
        body: "",
        context: groups(:top_layer)
      )

      CustomContent.create!(
        key: "event_application_confirmation",
        label: "Custom Content in another context",
        body: "",
        context: groups(:bottom_layer_one)
      )
    end

    it "renders custom content labels as dropdown options" do
      is_expected.to have_content "E-Mail senden"

      expect(menu).to have_link "Custom Content in context"
    end

    it "does not render custom content from another context" do
      expect(menu).not_to have_link "Custom Content in another context"
    end
  end
end
