# frozen_string_literal: true

# Copyright (c) 2026. BienenSchweiz. This file is part of
# hitobito and licensed under the Affero General Public License version 3
# or later. See the COPYING file at the top-level directory or at
# https://github.com/hitobito/hitobito

require "spec_helper"

describe PersonalDocumentAbility do
  subject(:ability) { Ability.new(user) }

  let(:other_person) { Fabricate(:person) }
  let(:own_document) { Fabricate(:personal_document, person: user) }
  let(:other_document) { Fabricate(:personal_document, person: other_person) }

  context "person without a role" do
    let(:user) { Fabricate(:person) }

    it "may read their own document" do
      is_expected.to be_able_to(:read, own_document)
    end

    it "may not read another person's document" do
      is_expected.not_to be_able_to(:read, other_document)
    end
  end

  context "layer_and_below_full" do
    let(:role) { Fabricate(Group::BottomLayer::Leader.name.to_sym, group: groups(:bottom_layer_one)) }
    let(:user) { role.person.reload }

    it "may not create documents" do
      is_expected.not_to be_able_to(:create, other_document)
    end

    it "may not update documents" do
      is_expected.not_to be_able_to(:update, other_document)
    end

    it "may not destroy documents" do
      is_expected.not_to be_able_to(:destroy, other_document)
    end
  end

  context "admin" do
    let(:role) { Fabricate(Group::TopGroup::Leader.name.to_sym, group: groups(:top_group)) }
    let(:user) { role.person.reload }

    it "may create documents for any person" do
      is_expected.to be_able_to(:create, other_document)
    end

    it "may update documents for any person" do
      is_expected.to be_able_to(:update, other_document)
    end

    it "may destroy documents for any person" do
      is_expected.to be_able_to(:destroy, other_document)
    end

    it "may read documents for any person" do
      is_expected.to be_able_to(:read, other_document)
    end
  end
end
