# frozen_string_literal: true

#  Copyright (c) 2026, Puzzle ITC. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito

require "spec_helper"

describe AdditionalAddressResource, type: :resource do
  let!(:user_role) {
    Fabricate(Group::BottomLayer::Leader.name.to_sym, person: Fabricate(:person), group: groups(:bottom_layer_one))
  }
  let!(:user) { user_role.person }
  let!(:role) {
    Fabricate(Group::BottomLayer::Leader.name.to_sym, person: Fabricate(:person), group: groups(:bottom_layer_one))
  }
  let(:person) { role.person }

  describe "creating" do
    let(:payload) do
      {
        data: {
          type: "additional_addresses",
          attributes: Fabricate.attributes_for(:additional_address).merge(
            contactable_id: person.id,
            contactable_type: "Person"
          )
        }
      }
    end

    let(:instance) do
      AdditionalAddressResource.build(payload)
    end

    it "copies the name fields from the contactable, since uses_contactable_name is not writable via the API" do
      expect {
        expect(instance.save).to eq(true), instance.errors.full_messages.to_sentence
      }.to change { AdditionalAddress.count }.by(1)

      new_address = AdditionalAddress.last
      expect(new_address.contactable).to eq person
      expect(new_address.first_name).to eq person.first_name
      expect(new_address.last_name).to eq person.last_name
    end
  end

  describe "updating" do
    let!(:additional_address) {
      Fabricate(:additional_address, contactable: person, uses_contactable_name: false, first_name: "Jane",
        last_name: "Doe")
    }

    let(:payload) do
      {
        id: additional_address.id.to_s,
        data: {
          id: additional_address.id.to_s,
          type: "additional_addresses",
          attributes: {
            organization: true,
            organization_name: "Acme Corp"
          }
        }
      }
    end

    let(:instance) do
      AdditionalAddressResource.find(payload)
    end

    it "works" do
      expect {
        expect(instance.update_attributes).to eq(true)
      }.to change { additional_address.reload.organization_name }.to("Acme Corp")
    end
  end

  describe "destroying" do
    let!(:additional_address) { Fabricate(:additional_address, contactable: person) }

    let(:instance) do
      AdditionalAddressResource.find(id: additional_address.id)
    end

    it "works" do
      expect {
        expect(instance.destroy).to eq(true)
      }.to change { AdditionalAddress.count }.by(-1)
    end
  end
end
