# frozen_string_literal: true

#  Copyright (c) 2026, Puzzle ITC. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "spec_helper"

describe "event/register/_manager_fields.html.haml" do
  let(:manager) { Person.new }

  before do
    assign(:policy_finder, Group::PrivacyPolicyFinder.for(group: groups(:top_group)))
    allow(view).to receive(:f).and_return(StandardFormBuilder.new(:manager, manager, view, {}))
  end

  it "renders company_name when address.company is enabled" do
    render

    expect(rendered).to have_field("manager_company_name")
  end

  it "does not render company_name when address.company is disabled" do
    allow(Person).to receive(:used_attributes)
      .and_return(Person.used_attributes - [:company, :company_name])

    render

    expect(rendered).to have_no_field("manager_company_name")
  end
end
