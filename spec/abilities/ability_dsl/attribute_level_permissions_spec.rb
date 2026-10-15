# frozen_string_literal: true

#  Copyright (c) 2026, hitobito AG. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito

require "spec_helper"

describe "Attribute-level permissions" do
  before do
    stub_const("TestAttributeAbility", Class.new(AbilityDsl::Base) do
      include AbilityDsl::Constraints::Person

      on(Person) do
        permission(:any).may(:update).herself
        permission(:any).may(:update).except_attrs(:first_name).herself
        permission(:layer_and_below_full).may(:update).in_same_layer_or_below
      end

      def person = subject
    end)

    stub_const("TestAbility", Class.new(Ability) do
      self.store = AbilityDsl::Store.new
    end)
    TestAbility.store.register(TestAttributeAbility)
  end

  let(:user) { people(:bottom_member) }

  subject(:ability) { TestAbility.new(user) }

  describe "except_attrs DSL" do
    context "when updating herself" do
      let(:user) { people(:bottom_member) }

      it "cannot update first_name" do
        expect(ability.can?(:update, user, :first_name)).to be false
      end

      it "can update last_name" do
        expect(ability.can?(:update, user, :last_name)).to be true
      end

      it "can still update overall" do
        expect(ability.can?(:update, user)).to be true
      end

      it "excludes first_name from permitted_attributes" do
        attrs = ability.permitted_attributes(:update, user)
        expect(attrs).not_to include(:first_name)
        expect(attrs).to include(:last_name)
      end
    end

    context "when updating another person" do
      let(:user) do
        Fabricate(Group::BottomLayer::Leader.sti_name, group: roles(:bottom_member).group).person
      end
      let(:other) { people(:bottom_member) }

      it "can update first_name (no attribute restriction for this path)" do
        # first make sure the user has permission to update other in general
        expect(ability.can?(:update, other)).to be true

        # then check that the attribute restriction does not apply when updating another person
        expect(ability.can?(:update, other, :first_name)).to be true
      end

      it "includes first_name in permitted_attributes" do
        attrs = ability.permitted_attributes(:update, other)
        expect(attrs).to include(:first_name)
      end
    end
  end
end
