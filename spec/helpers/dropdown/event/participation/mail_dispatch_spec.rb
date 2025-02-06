# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

require "spec_helper"

describe Dropdown::Event::Participation::MailDispatch do
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

  before do
    CustomContent.create!(key: "event_application_confirmation", label: "Custom Content Label 1", body: "")
  end

  def menu = subject.find(".btn-group > ul.dropdown-menu")

  it "renders custom content labels as dropdown options" do
    is_expected.to have_content "E-Mail senden"

    expect(menu).to have_link "Custom Content Label 1"
  end
end
