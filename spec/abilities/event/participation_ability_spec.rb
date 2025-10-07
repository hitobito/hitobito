# frozen_string_literal: true

#  Copyright (c) 2023, Pfadibewegung Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "spec_helper"

describe Event::ParticipationAbility do
  let(:user) { role.person }

  subject { Ability.new(user) }

  context "creating participation for herself" do
    let(:participation) { Event::Participation.new(event: course, person: user) }
    let(:role) { Fabricate(Group::BottomLayer::Leader.name, group: groups(:bottom_layer_one)) }

    context "in event which can be shown" do
      let(:course) { Event::Course.new(groups: [groups(:bottom_layer_one)], globally_visible: false) }

      it "may create participation for herself" do
        is_expected.to be_able_to(:create, participation)
      end
    end

    context "in globally visible event" do
      let(:course) { Event::Course.new(groups: [groups(:bottom_layer_two)], globally_visible: true) }

      it "may create participation for herself" do
        is_expected.to be_able_to(:create, participation)
      end
    end

    context "in event which cannot be shown" do
      let(:course) { Event::Course.new(groups: [groups(:bottom_layer_two)], globally_visible: false) }

      it "may not create participation for herself" do
        is_expected.not_to be_able_to(:create, participation)
      end
    end
  end

  context "manager inherited permissions" do
    let(:participant) { Fabricate(:person) }
    let(:manager) { Fabricate(:person) }
    let!(:manager_relation) { PeopleManager.create(manager: manager, managed: participant) }

    let(:course) { Fabricate(:course) }
    let(:participation) { Fabricate(:event_participation, event: course, participant: participant) }

    subject { Ability.new(user) }

    context "for self" do
      let(:user) { participant }

      context "if event applications are not possible / cancelable" do
        before do
          course.update application_opening_at: 1.week.from_now
        end

        it { is_expected.to be_able_to :show, participation }
        it { is_expected.to be_able_to :show_details, participation }
        it { is_expected.not_to be_able_to :create, participation }
        it { is_expected.not_to be_able_to :destroy, participation }
      end

      context "if event application is possible / cancelable" do
        before { course.update(state: :application_open, applications_cancelable: true) }

        it { is_expected.to be_able_to :show, participation }
        it { is_expected.to be_able_to :show_details, participation }
        it { is_expected.to be_able_to :create, participation }
        it { is_expected.to be_able_to :destroy, participation }

        context "but event is in archived group" do
          before { course.groups.each(&:archive!) }

          it { is_expected.not_to be_able_to :create, participation }
        end
      end

      context "as event leader" do
        let!(:leader_role) { Fabricate(Event::Role::Leader.name, participation: participation) }
        let(:other_participation) { Fabricate(:event_participation, event: course) }

        it { is_expected.to be_able_to :show, other_participation }
        it { is_expected.to be_able_to :show_details, other_participation }
      end
    end

    context "for manager" do
      let(:user) { manager }

      context "if event applications are not possible / cancelable" do
        before do
          course.update application_opening_at: 1.week.from_now
        end

        it { is_expected.to be_able_to :show, participation }
        it { is_expected.to be_able_to :show_details, participation }
        it { is_expected.not_to be_able_to :create, participation }
        it { is_expected.not_to be_able_to :destroy, participation }
      end

      context "if event application is possible / cancelable" do
        before { course.update(state: :application_open, applications_cancelable: true) }

        it { is_expected.to be_able_to :show, participation }
        it { is_expected.to be_able_to :show_details, participation }
        it { is_expected.to be_able_to :create, participation }
        it { is_expected.to be_able_to :destroy, participation }

        context "but event is in archived group" do
          before { course.groups.each(&:archive!) }

          it { is_expected.not_to be_able_to :create, participation }
        end

        context "of event leader" do
          let!(:leader_role) { Fabricate(Event::Role::Leader.name, participation: participation) }
          let(:other_participation) { Fabricate(:event_participation, event: course) }

          it "does not inherit show permissions on participants" do
            is_expected.not_to be_able_to :show, other_participation
          end
          it "does not inherit show_details permissions on participants" do
            is_expected.not_to be_able_to :show_details, other_participation
          end
        end
      end
    end

    context "for unrelated user" do
      let(:user) { Fabricate(:person) }

      context "if event applications are not possible / cancelable" do
        it { is_expected.not_to be_able_to :show, participation }
        it { is_expected.not_to be_able_to :show_details, participation }
        it { is_expected.not_to be_able_to :create, participation }
        it { is_expected.not_to be_able_to :destroy, participation }
      end

      context "if event application is possible / cancelable" do
        before { course.update(state: :application_open, applications_cancelable: true) }

        it { is_expected.not_to be_able_to :show, participation }
        it { is_expected.not_to be_able_to :show_details, participation }
        it { is_expected.not_to be_able_to :create, participation }
        it { is_expected.not_to be_able_to :destroy, participation }

        context "but event is in archived group" do
          before { course.groups.each(&:archive!) }

          it { is_expected.not_to be_able_to :create, participation }
        end
      end
    end
  end
end
