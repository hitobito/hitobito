# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_youth.

require "spec_helper"

describe PeopleManagerAbility do
  let(:top_leader) { people(:top_leader) }
  let(:bottom_member) { people(:bottom_member) }

  subject(:ability) { Ability.new(person) }

  def build(managed: nil, manager: nil)
    PeopleManager.new(managed: managed, manager: manager)
  end

  before do
    allow(FeatureGate).to receive(:enabled?).and_return false
    allow(FeatureGate).to receive(:enabled?).with("people.people_managers").and_return true
    allow(FeatureGate).to receive(:enabled?).with("people.people_managers.self_service_managed_creation")
      .and_return true
  end

  describe :show do
    let(:person) { Fabricate(:person) }
    let(:manager) { Fabricate(:person) }
    let(:managed) { bottom_member }
    let(:people_manager) { build(managed: managed, manager: manager) }

    context "with no relation" do
      it { is_expected.not_to be_able_to(:show, people_manager) }
    end

    context "with leader role on participation event" do
      let(:event) { events(:top_event) }

      before do
        roles = {person => Event::Role::Leader, people_manager.managed => Event::Role::Participant}
        roles.map do |person, role|
          Fabricate(role.name, participation: Fabricate(:event_participation, event: event, participant: person))
        end
        people_manager.save
        people_manager.reload
      end

      it { is_expected.to be_able_to(:show, people_manager) }
    end

    context "with layer permissions" do
      let(:person) { top_leader }

      it { is_expected.to be_able_to(:show, people_manager) }
    end
  end

  def person_with_change_managers_but_not_update_email
    Fabricate(Group::BottomLayer::LocalGuide.name.to_sym, group: groups(:bottom_layer_one)).person
  end

  def managed_with_role_in_other_layer
    Fabricate(Group::BottomLayer::Member.name.to_sym, group: groups(:bottom_layer_one)).person.tap do |managed|
      Fabricate(Group::BottomLayer::Leader.name.to_sym, group: groups(:bottom_layer_two), person: managed)
    end
  end

  describe :create_manager do
    context "top leader" do
      let(:person) { top_leader }

      it "may create manager for bottom_member" do
        expect(ability).to be_able_to(:create_manager, build(managed: bottom_member))
      end

      it "may not create manager for himself" do
        expect(ability).not_to be_able_to(:create_manager, build(managed: top_leader))
      end

      it "may create manager for new record, as self-service creation is always allowed" do
        expect(ability).to be_able_to(:create_manager, build(managed: Person.new))
      end
    end

    context "bottom member" do
      let(:person) { bottom_member }

      it "may not create manager for top_leader" do
        expect(ability).not_to be_able_to(:create_manager, build(managed: top_leader))
      end

      it "may not create manager for himself" do
        expect(ability).not_to be_able_to(:create_manager, build(managed: bottom_member))
      end

      it "may create manager for new record, as self-service creation is always allowed" do
        expect(ability).to be_able_to(:create_manager, build(managed: Person.new))
      end
    end

    context "local guide" do
      let(:person) { Fabricate(Group::BottomLayer::LocalGuide.name.to_sym, group: groups(:bottom_layer_one)).person }

      it "may create manager for bottom member" do
        expect(ability).to be_able_to(:create_manager, build(managed: bottom_member))
      end

      it "may not create manager for bottom member because they have a role outside of person layer permissions" do
        Fabricate(Group::BottomLayer::Leader.name.to_sym, group: groups(:bottom_layer_two), person: bottom_member)
        expect(ability).not_to be_able_to(:create_manager, build(managed: bottom_member))
      end
    end
  end

  describe :destroy_manager do
    context "top leader" do
      let(:person) { top_leader }

      it "may destroy manager of bottom_member" do
        expect(ability).to be_able_to(:destroy_manager, build(managed: bottom_member))
      end

      it "may not destroy his own manager" do
        expect(ability).not_to be_able_to(:destroy_manager, build(managed: top_leader))
      end

      it "may not destroy manager of new record, as it has none to destroy" do
        expect(ability).not_to be_able_to(:destroy_manager, build(managed: Person.new))
      end
    end

    context "bottom member" do
      let(:person) { bottom_member }

      it "may not destroy manager of top_leader" do
        expect(ability).not_to be_able_to(:destroy_manager, build(managed: top_leader))
      end

      it "may not destroy his own manager" do
        expect(ability).not_to be_able_to(:destroy_manager, build(managed: bottom_member))
      end

      it "may not destroy manager of new record, as it has none to destroy" do
        expect(ability).not_to be_able_to(:destroy_manager, build(managed: Person.new))
      end
    end

    context "local guide" do
      let(:person) { Fabricate(Group::BottomLayer::LocalGuide.name.to_sym, group: groups(:bottom_layer_one)).person }

      it "may destroy manager of bottom member" do
        expect(ability).to be_able_to(:destroy_manager, build(managed: bottom_member))
      end

      it "may destroy manager of bottom member even if bottom member has role outside of person layer permissions" do
        Fabricate(Group::BottomLayer::Leader.name.to_sym, group: groups(:bottom_layer_two), person: bottom_member)
        expect(ability).to be_able_to(:destroy_manager, build(managed: bottom_member))
      end
    end
  end
end
