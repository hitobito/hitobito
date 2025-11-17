# frozen_string_literal: true

#  Copyright (c) 2023, CEVI Schweiz, Pfadibewegung Schweiz,
#  Jungwacht Blauring Schweiz, Pro Natura, Stiftung für junge Auslandschweizer.
#  This file is part of hitobito_youth and
#  licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_youth.

require "spec_helper"

describe PersonAbility do
  let(:ability) { Ability.new(manager) }
  let(:manager) { Fabricate(:person) }
  let(:member_role) { roles(:bottom_member) }
  let(:member) { member_role.person }
  let(:actions) {
    [:show, :show_details, :show_full, :history, :update, :update_email,
      :primary_group, :log, :totp_reset]
  }

  subject { ability }

  context "manager permission on managed person" do
    it "may not access member" do
      actions.each do |action|
        is_expected.not_to be_able_to(action, member)
      end
    end

    it "may not create households" do
      is_expected.to_not be_able_to(:create_households, Person)
    end

    it "may not lookup manageds" do
      is_expected.to_not be_able_to(:lookup_manageds, Person)
    end

    it "may access member if is manager of member" do
      member.people_managers.create(manager_id: manager.id)
      actions.each do |action|
        is_expected.to be_able_to(action, member)
      end
    end
  end

  context "manager permission" do
    before { member.people_managers.create(manager_id: manager.id) }

    it "may create households" do
      is_expected.to be_able_to(:create_households, Person)
    end

    it "may not lookup manageds" do
      is_expected.to_not be_able_to(:lookup_manageds, Person)
    end
  end

  context "group leader permission to change managers" do
    it "cannot change managers" do
      # precondition: no relation to member, so cannot update
      is_expected.not_to be_able_to(:update, member)

      # assertion: does not have write permission via a role, so cannot change managers
      is_expected.not_to be_able_to(:change_managers, member)
    end

    it "may lookup manageds if has write permissions on managed person" do
      Fabricate(Group::BottomLayer::Leader.name.to_sym,
        group_id: member_role.group_id,
        person: manager)
      is_expected.to be_able_to(:lookup_manageds, Person)
    end

    it "cannot change managers if only related to the managed person via manager relation" do
      member.people_managers.create(manager_id: manager.id)
      # precondition: is manager of member, so can update
      is_expected.to be_able_to(:update, member)

      # assertion: does not have write permission via a role (only via manager relation),
      # so cannot change managers
      is_expected.not_to be_able_to(:change_managers, member)
    end

    it "can change managers if has write permissions on managed person" do
      Fabricate(Group::BottomLayer::Leader.name.to_sym,
        group_id: member_role.group_id,
        person: manager)
      # precondition: has write permission, so can update
      is_expected.to be_able_to(:update, member)

      # assertion: has write permission, so can change managers
      is_expected.to be_able_to(:change_managers, member)
    end

    it "can change managers if write permissions and is manager at the same time" do
      Fabricate(Group::BottomLayer::Leader.name.to_sym,
        group_id: member_role.group_id,
        person: manager)
      member.people_managers.create(manager_id: manager.id)
      # precondition: has write permissions and is manager of member, so can update
      is_expected.to be_able_to(:update, member)

      # assertion: has write permissions via a role, so can change managers, regardless of
      # the additional manager relation
      is_expected.to be_able_to(:change_managers, member)
    end

    it "cannot change own managers" do
      Fabricate(Group::BottomLayer::Leader.name.to_sym,
        group_id: member_role.group_id,
        person: member)
      # precondition: has write permission, so can update
      expect(Ability.new(member)).to be_able_to(:update, member)

      # assertion: has write permission, but can still not change own managers
      expect(Ability.new(member)).not_to be_able_to(:change_managers, member)
    end
  end
end
