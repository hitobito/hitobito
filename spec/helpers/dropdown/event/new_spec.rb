# frozen_string_literal: true

#  Copyright (c) 2026, Hitobito AG. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "spec_helper"

describe Dropdown::Event::New do
  include Rails.application.routes.url_helpers
  include FormatHelper
  include LayoutHelper
  include UtilityHelper

  let(:current_user) { people(:top_leader) }
  let(:group) { groups(:top_group) }
  let(:dropdown) { described_class.new(self, group, Event) }
  let(:template) { events(:template) }

  subject { Capybara.string(dropdown.to_s) }

  before { allow(self).to receive(:can?).and_return(true) }

  it "renders nothing when the user may not create events" do
    allow(self).to receive(:can?).and_return(false)

    expect(dropdown.to_s).to be_blank
  end

  it "renders a dropdown listing the template" do
    is_expected.to have_content "Anlass erstellen"
    is_expected.to have_css("ul.dropdown-menu li", text: "Vorlage")
  end

  it "links the template item to new with source_id" do
    is_expected.to have_css(%(a[href$="events/new?source_id=#{template.id}"]))
  end

  it "loads the template translations once, not per template" do
    Fabricate(:event, groups: [groups(:top_layer)], template: true, name: "Alpha")

    expect { dropdown.to_s }.to make.db_queries.with("Event::Translation Load" => 1)
    is_expected.to have_css("ul.dropdown-menu li", count: 2)
  end

  it "renders a plain button when no templates are applicable" do
    events(:template).destroy
    is_expected.to have_content "Anlass erstellen"
    is_expected.not_to have_css("ul.dropdown-menu")
  end
end
