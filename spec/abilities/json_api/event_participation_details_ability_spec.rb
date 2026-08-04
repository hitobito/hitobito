# frozen_string_literal: true

#  Copyright (c) 2026, Pfadibewegung Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito

require "spec_helper"

describe JsonApi::EventParticipationDetailsAbility do
  let(:participation) { event_participations(:top) } # bottom_member in top_course
  let(:event) { participation.event } # in top_layer

  def accessible_by(person)
    person = people(person) unless person.is_a?(Person)
    Event::Participation.all.accessible_by(described_class.new(person))
  end

  def person_with_role(role_type, group)
    Fabricate(role_type.sti_name, group: groups(group)).person
  end

  describe "layer and group permissions" do
    it "may read with layer_and_below_full" do
      expect(accessible_by(:top_leader)).to eq [participation]
    end

    it "may not read with layer_and_below_read only" do
      event.update!(groups: [groups(:bottom_layer_one)])
      person = person_with_role(Group::BottomLayer::Member, :bottom_layer_one)
      expect(accessible_by(person)).to be_empty
    end

    it "may read with layer_full" do
      person = person_with_role(Group::TopGroup::LocalGuide, :top_group)
      expect(accessible_by(person)).to eq [participation]
    end

    it "may not read with layer_read only" do
      person = person_with_role(Group::TopGroup::LocalSecretary, :top_group)
      expect(accessible_by(person)).to be_empty
    end

    it "may read with group_and_below_full" do
      event.update!(groups: [groups(:top_group)])
      person = person_with_role(Group::TopGroup::GroupManager, :top_group)
      expect(accessible_by(person)).to eq [participation]
    end

    it "may read with group_full" do
      event.update!(groups: [groups(:top_group)])
      person = person_with_role(Group::TopGroup::Secretary, :top_group)
      expect(accessible_by(person)).to eq [participation]
    end

    it "may not read with group_and_below_read only" do
      event.update!(groups: [groups(:top_group)])
      person = person_with_role(Group::TopGroup::Member, :top_group)
      expect(accessible_by(person)).to be_empty
    end
  end

  describe "event roles" do
    let!(:other) { Fabricate(:event_participation, event: event, active: true) }
    let(:participant) { participation.participant }

    it "may read with participations_full" do
      expect(event_roles(:top_leader).class.permissions).to include :participations_full
      expect(accessible_by(participant)).to match_array [participation, other]
    end

    it "may read with participations_read_details" do
      event_roles(:top_leader).update!(type: Event::Role::Helper.sti_name)
      expect(Event::Role::Helper.permissions).to eq [:participations_read_details]
      expect(accessible_by(participant)).to match_array [participation, other]
    end

    it "may not read others with participations_read only" do
      event_roles(:top_leader).update!(type: Event::Role::Speaker.sti_name)
      expect(Event::Role::Speaker.permissions).to eq [:participations_read]
      # her own participation stays readable
      expect(accessible_by(participant)).to eq [participation]
    end

    it "may not read others of an event with visible participations" do
      event_roles(:top_leader).update!(type: Event::Role::Participant.sti_name)
      event.update!(participations_visible: true)
      expect(accessible_by(participant)).to eq [participation]
    end
  end

  describe "pending applications" do
    # leader of top_course, but only layer_and_below_read in bottom_layer_one
    let(:person) { participation.participant }
    let!(:other_course) { Fabricate(:course, groups: [groups(:bottom_layer_two)]) }
    let!(:other_participation) do
      Fabricate(:event_participation, event: other_course,
        application: Fabricate(:event_application))
    end

    it "may not read applicants from outside of the own layers" do
      expect(other_participation).not_to be_active
      expect(accessible_by(person)).to eq [participation]
    end
  end
end
