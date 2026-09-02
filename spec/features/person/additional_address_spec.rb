# frozen_string_literal: true

#  Copyright (c) 2026, Puzzle ITC. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito

require "spec_helper"

describe "additional address form toggles", js: true do
  let(:person) { people(:top_leader) }
  let(:group) { groups(:top_group) }
  let(:uses_contactable_name_checkbox_id) { "person_additional_addresses_attributes_0_uses_contactable_name" }
  let(:organization_checkbox_id) { "person_additional_addresses_attributes_0_organization" }
  let(:first_name_field_id) { "person_additional_addresses_attributes_0_first_name" }
  let(:organization_name_field_id) { "person_additional_addresses_attributes_0_organization_name" }

  before do
    allow(Settings.additional_address).to receive(:enabled).and_return(true)
  end

  describe "organization toggle" do
    before do
      Fabricate(:additional_address, contactable: person, label: "Rechnung", uses_contactable_name: false,
        first_name: "Jane", last_name: "Doe")

      sign_in(person)
      visit edit_group_person_path(group_id: group.id, id: person.id)
    end

    it "only reveals organization_name once organization is checked, and hides it again when unchecked" do
      expect(page).to have_selector("##{organization_name_field_id}", visible: :hidden)

      find("##{organization_checkbox_id}").click
      expect(page).to have_selector("##{organization_name_field_id}", visible: :visible)

      find("##{organization_name_field_id}").set("Acme Corp")
      expect(find("##{organization_name_field_id}", visible: :visible).value).to eq "Acme Corp"

      find("##{organization_checkbox_id}").click
      expect(page).to have_selector("##{organization_name_field_id}", visible: :hidden)
    end
  end

  describe "uses_contactable_name toggle" do
    before do
      Fabricate(:additional_address, contactable: person, label: "Rechnung", uses_contactable_name: true)

      sign_in(person)
      visit edit_group_person_path(group_id: group.id, id: person.id)
    end

    it "reveals first_name/last_name/organization once unchecked, and hides them again when checked" do
      expect(page).to have_selector("##{first_name_field_id}", visible: :hidden)
      expect(page).to have_selector("##{organization_checkbox_id}", visible: :hidden)

      find("##{uses_contactable_name_checkbox_id}").click
      expect(page).to have_selector("##{first_name_field_id}", visible: :visible)
      expect(page).to have_selector("##{organization_checkbox_id}", visible: :visible)

      find("##{first_name_field_id}").set("Jane")
      expect(find("##{first_name_field_id}", visible: :visible).value).to eq "Jane"

      find("##{uses_contactable_name_checkbox_id}").click
      expect(page).to have_selector("##{first_name_field_id}", visible: :hidden)
      expect(page).to have_selector("##{organization_checkbox_id}", visible: :hidden)
    end
  end
end
