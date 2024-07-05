# frozen_string_literal: true

#  Copyright (c) 2023, Schweizer Wanderwege. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "spec_helper"

describe SocialAccountResource, type: :resource do
  let!(:user_role) { Fabricate(Group::BottomLayer::Leader.name.to_sym, person: Fabricate(:person), group: groups(:bottom_layer_one)) }
  let!(:user) { user_role.person }
  let!(:role) { Fabricate(Group::BottomLayer::Leader.name.to_sym, person: Fabricate(:person), group: groups(:bottom_layer_one)) }
  let(:person) { role.person }

  around do |example|
    RSpec::Mocks.with_temporary_scope do
      Graphiti.with_context(double({current_ability: Ability.new(user)})) { example.run }
    end
  end

  describe "creating" do
    let(:payload) do
      {
        data: {
          type: "social_accounts",
          attributes: Fabricate.attributes_for(:social_account).merge(
            contactable_id: person.id,
            contactable_type: "Person",
            name: "mis-grosi"
          )
        }
      }
    end

    let(:instance) do
      SocialAccountResource.build(payload)
    end

    it "works" do
      expect {
        expect(instance.save).to eq(true), instance.errors.full_messages.to_sentence
      }.to change { SocialAccount.count }.by(1)

      new_social_account = SocialAccount.last
      expect(new_social_account.contactable).to eq person
      expect(new_social_account.name).to eq "mis-grosi"
    end
  end

  describe "updating" do
    let!(:social_account) { Fabricate(:social_account, contactable: person) }

    let(:payload) do
      {
        id: social_account.id.to_s,
        data: {
          id: social_account.id.to_s,
          type: "social_accounts",
          attributes: {
            name: "mis-grosi"
          }
        }
      }
    end

    let(:instance) do
      SocialAccountResource.find(payload)
    end

    it "works" do
      expect {
        expect(instance.update_attributes).to eq(true)
      }.to change { social_account.reload.name }.to("mis-grosi")
    end
  end

  describe "destroying" do
    let!(:social_account) { Fabricate(:social_account, contactable: person) }

    let(:instance) do
      SocialAccountResource.find(id: social_account.id)
    end

    it "works" do
      expect {
        expect(instance.destroy).to eq(true)
      }.to change { SocialAccount.count }.by(-1)
    end
  end
end
