# frozen_string_literal: true

#  Copyright (c) 2026, Puzzle ITC. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito

require "spec_helper"

describe "people/_form.html.haml" do
  let(:group) { groups(:top_group) }
  let(:person) { people(:top_leader).decorate }
  let(:dom) { Capybara::Node::Simple.new(@rendered) }

  before do
    allow(view).to receive_messages(parents: [group], entry: person, model_class: Person, path_args: [group, person])
    allow(controller).to receive_messages(current_user: people(:top_leader))
  end

  it "disables autocomplete for the form" do
    @rendered = render partial: "people/form"

    expect(dom.find("form")["autocomplete"]).to eq "off"
  end

  describe "company fields" do
    it "renders company_name and company when address.company is enabled" do
      @rendered = render partial: "people/form"

      expect(dom).to have_field("person_company_name")
      expect(dom).to have_field("person_company")
    end

    it "does not render company_name and company when address.company is disabled" do
      allow(Person).to receive(:used_attributes)
        .and_return(Person.used_attributes - [:company, :company_name])

      @rendered = render partial: "people/form"

      expect(dom).to have_no_field("person_company_name")
      expect(dom).to have_no_field("person_company")
    end
  end
end
