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
    allow(FeatureGate).to receive(:enabled?).with("people.people_managers.self_service_managed_creation").and_return true
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

  [:create_manager, :destroy_manager].each do |action|
    context "top leader" do
      let(:person) { top_leader }

      describe "#{action} manager" do
        it "may change manager of bottom_member" do
          expect(ability).to be_able_to(action, build(managed: bottom_member))
        end

        it "may not change his own manager" do
          expect(ability).not_to be_able_to(action, build(managed: top_leader))
        end

        it "may change manager of new record" do
          expect(ability).to be_able_to(action, build(managed: Person.new))
        end
      end
    end

    context "bottom member" do
      let(:person) { bottom_member }

      describe "#{action} manager" do
        it "may not change manager of top_leader" do
          expect(ability).not_to be_able_to(action, build(managed: top_leader))
        end

        it "may not change his own manager" do
          expect(ability).not_to be_able_to(action, build(managed: bottom_member))
        end

        it "may change manager of new record" do
          expect(ability).to be_able_to(action, build(managed: Person.new))
        end
      end
    end
  end
end
