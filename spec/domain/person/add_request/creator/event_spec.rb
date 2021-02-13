# encoding: utf-8

#  Copyright (c) 2012-2015, Pfadibewegung Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "spec_helper"

describe Person::AddRequest::Creator::Event do

  let(:primary_layer) { person.primary_group.layer_group }
  let(:person) { Fabricate(Group::BottomLayer::Member.name, group: groups(:bottom_layer_two)).person }
  let(:requester) { Fabricate(Group::BottomLayer::Leader.name, group: groups(:bottom_layer_one)).person }

  let(:event) { Fabricate(:event, groups: [groups(:bottom_layer_one)]) }
  let(:entity) do
    Fabricate.build(Event::Role::Participant.name,
                    participation: Fabricate.build(:event_participation, event: event, person: person))
  end

  let(:ability) { Ability.new(requester) }

  subject { Person::AddRequest::Creator::Event.new(entity, ability) }

  before { primary_layer.update_column(:require_person_add_requests, true) }

  context "#required" do

    it "is true if primary layer activated requests" do
      expect(subject).to be_required
    end

    it "is true if deleted role already exists" do
      Fabricate(Group::BottomGroup::Member.name, group: groups(:bottom_group_one_one), person: person, deleted_at: 1.year.ago)
      expect(subject).to be_required
    end

    it "is false if primary layer deactivated requests" do
      primary_layer.update_column(:require_person_add_requests, false)
      expect(subject).not_to be_required
    end

    it "is false if role is invalid" do
      entity = Fabricate.build(Event::Role::Participant.name,
                               participation: Fabricate.build(:event_participation, event: event))
      creator = Person::AddRequest::Creator::Event.new(entity, ability)
      expect(creator).not_to be_required
    end

    it "is false if person has no primary group" do
      person.update_column(:primary_group_id, nil)
      expect(subject).not_to be_required
    end

    it "is false if requester can already show the person" do
      Fabricate(Group::BottomLayer::Member.name, group: groups(:bottom_layer_two), person: requester)
      expect(subject).not_to be_required
    end

    it "is false if person already participates in event" do
      Fabricate(Event::Role::Cook.name, participation: entity.participation)
      entity.participation.reload
      expect(subject).not_to be_required
    end

  end

  context "#create_request" do

    it "creates event request" do
      subject.create_request

      request = subject.request
      expect(request).to be_persisted
      expect(request.body).to eq(event)
      expect(request.role_type).to eq(entity.type)
      expect(request.requester).to eq(requester)
      expect(request.person).to eq(person)
    end

    it "creates group request if deleted role already exists" do
      Fabricate(Group::BottomGroup::Member.name, group: groups(:bottom_group_one_one), person: person, deleted_at: 1.year.ago)

      expect do
        subject.create_request
      end.to change { Person::AddRequest.count }.by(1)
      expect(subject.request).to be_persisted
    end

    it "schedules emails" do
      expect do
        subject.create_request
      end.to change { Delayed::Job.count }.by(1)
    end

    it "does not persist if request already exists" do
      Person::AddRequest::Event.create!(
        person: person,
        requester: requester,
        body: event,
        role_type: Event::Role::Speaker.sti_name)

      expect do
        subject.create_request
      end.not_to change { Delayed::Job.count }
      expect(subject.request).to be_new_record
      expect(subject.error_message).to match(/Person wurde bereits angefragt./)
    end
  end

end
