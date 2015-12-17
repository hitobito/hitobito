# encoding: utf-8

#  Copyright (c) 2012-2015, Pfadibewegung Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require 'spec_helper'

describe Person::AddRequest::Approver do

  let(:person) { Fabricate(Group::BottomLayer::Member.name, group: groups(:bottom_layer_two)).person }
  let(:requester) { Fabricate(Group::BottomLayer::Leader.name, group: groups(:bottom_layer_one)).person }

  let(:user) { Fabricate(Group::BottomLayer::Leader.name, group: groups(:bottom_layer_two)).person }

  subject { Person::AddRequest::Approver.for(request, user) }

  # TODO: test what happens if request is approved after the role/participation/subscription was created

  context 'Group' do

    let(:group) { groups(:bottom_group_one_one) }

    let(:request) do
      Person::AddRequest::Group.create!(
        person: person,
        requester: requester,
        body: group,
        role_type: Group::BottomGroup::Member.sti_name)
    end

    it 'resolves correct subclass based on request' do
      is_expected.to be_a(Person::AddRequest::Approver::Group)
    end

    context '#approve' do

      # load before to get correct change counts
      before { subject }

      it 'creates a new role' do
        expect do
          subject.approve
        end.to change { Role.count }.by(1)

        role = person.roles.where(group_id: group.id).first
        expect(role).to be_a(Group::BottomGroup::Member)
      end

      it 'destroys request' do
        expect do
          subject.approve
        end.to change { Person::AddRequest.count }.by(-1)
      end

      it 'schedules email' do
        expect do
          subject.approve
        end.to change { Delayed::Job.count }.by(1)
      end

      it 'creates person log entry for role and for request' do
        expect do
          subject.approve
        end.to change { PaperTrail::Version.count }.by(2)
      end

    end

    context 'reject' do

      # load before to get correct change counts
      before { subject }

      it 'destroys request' do
        expect do
          subject.reject
        end.to change { Person::AddRequest.count }.by(-1)
      end

      it 'schedules email' do
        expect do
          subject.reject
        end.to change { Delayed::Job.count }.by(1)
      end

      it 'creates person log entry for request' do
        expect do
          subject.reject
        end.to change { PaperTrail::Version.count }.by(1)
      end

      context 'as requester' do

        let(:user) { requester }

        it 'does not schedule email' do
          expect do
            subject.reject
          end.not_to change { Delayed::Job.count }
        end

        it 'creates person log entry for request' do
          expect do
            subject.reject
          end.to change { PaperTrail::Version.count }.by(1)
        end

      end

    end

  end

  context 'MailingList' do

    let(:group) { groups(:bottom_group_one_one) }
    let(:list) { Fabricate(:mailing_list, group: group) }

    let(:request) do
      Person::AddRequest::MailingList.create!(
        person: person,
        requester: requester,
        body: list)
    end

    it 'resolves correct subclass based on request' do
      is_expected.to be_a(Person::AddRequest::Approver::MailingList)
    end

    context '#approve' do

      # load before to get correct change counts
      before { subject }

      it 'creates a new subscription' do
        expect do
          subject.approve
        end.to change { Subscription.count }.by(1)

        s = list.subscriptions.first
        expect(s.subscriber).to eq(person)
      end
    end
  end

  context 'Event' do

    let(:group) { groups(:bottom_group_one_one) }
    let(:event) { Fabricate(:event, groups: [group]) }

    let(:request) do
      Person::AddRequest::Event.create!(
        person: person,
        requester: requester,
        body: event,
        role_type: Event::Role::Cook.sti_name)
    end

    it 'resolves correct subclass based on request' do
      is_expected.to be_a(Person::AddRequest::Approver::Event)
    end

    context '#approve' do

      # TODO test that answers are created

      # load before to get correct change counts
      before { subject }

      it 'creates a new participation' do
        expect do
          subject.approve
        end.to change { Event::Participation.count }.by(1)

        p = person.event_participations.first
        expect(p).to be_active
        expect(p.roles.count).to eq(1)
        expect(p.roles.first).to be_a(Event::Role::Cook)
      end

    end
  end

  context 'Course' do
    let(:group) { groups(:bottom_layer_one) }
    let(:event) { Fabricate(:course, groups: [group]) }

    let(:request) do
      Person::AddRequest::Event.create!(
        person: person,
        requester: requester,
        body: event,
        role_type: Event::Course::Role::Participant.sti_name)
    end

    it 'creates a new participation' do
      expect do
        subject.approve
      end.to change { Event::Participation.count }.by(1)

      p = person.event_participations.first
      expect(p).to be_active
      expect(p.roles.count).to eq(1)
      expect(p.roles.first).to be_a(Event::Course::Role::Participant)
    end
  end

end
