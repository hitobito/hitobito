# frozen_string_literal: true

#  Copyright (c) 2026, Puzzle ITC. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito

require "spec_helper"

describe "roles/_person_fields.html.haml" do
  let(:role) { Role.new(person: Person.new).decorate }
  let(:form_builder) { StandardFormBuilder.new(:role, role, view, {builder: StandardFormBuilder}) }

  before do
    assign(:policy_finder, Group::PrivacyPolicyFinder.for(group: groups(:top_group)))
    allow(view).to receive(:entry).and_return(role)
  end

  it "renders company fields for the new person when address.company is enabled" do
    render locals: {f: form_builder}

    expect(rendered).to have_field("role_new_person_company_name", visible: :all)
    expect(rendered).to have_field("role_new_person_company", visible: :all)
  end

  it "does not render company fields when address.company is disabled" do
    allow(Person).to receive(:used_attributes)
      .and_return(Person.used_attributes - [:company, :company_name])

    render locals: {f: form_builder}

    expect(rendered).to have_no_field("role_new_person_company_name", visible: :all)
    expect(rendered).to have_no_field("role_new_person_company", visible: :all)
  end
end
