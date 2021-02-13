# encoding: utf-8

#  Copyright (c) 2012-2015, Pfadibewegung Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "spec_helper"

describe Person::AddRequest::Approver::Event do
  let(:person) { Fabricate(Group::BottomLayer::Member.name, group: groups(:bottom_layer_two)).person }
  let(:requester) { Fabricate(Group::BottomLayer::Leader.name, group: groups(:bottom_layer_one)).person }

  let(:user) { Fabricate(Group::BottomLayer::Leader.name, group: groups(:bottom_layer_two)).person }

  subject { Person::AddRequest::Approver.for(request, user) }

  context "Event" do
    let(:group) { groups(:bottom_group_one_one) }
    let(:event) { Fabricate(:event, groups: [group]) }

    let(:request) do
      Person::AddRequest::Event.create!(
        person: person,
        requester: requester,
        body: event,
        role_type: Event::Role::Participant.sti_name)
    end

    it "resolves correct subclass based on request" do
      is_expected.to be_a(Person::AddRequest::Approver::Event)
    end

    context "#approve" do
      before do
        Fabricate(:event_question, event: event)
        Fabricate(:event_question, event: event)
        event.reload
      end

      # load before to get correct change counts
      before { subject }

      it "creates a new participation and sends email" do
        expect_enqueued_mail_jobs(count: 1) do
          expect do
            subject.approve
          end.to change { Event::Participation.count }.by(1)
        end

        p = person.event_participations.first
        expect(p).to be_active
        expect(p.roles.count).to eq(1)
        expect(p.roles.first).to be_a(Event::Role::Participant)
        expect(p.answers.count).to eq(2)
        expect(p.application).to be_nil
      end

      it "creates new participation and does not send email" do
        person.update(email: nil)
        expect_no_enqueued_mail_jobs do
          expect { subject.approve }.to change { Event::Participation.count }.by(1)
        end
      end
    end

    context "#reject" do
      it "sends email if email is set" do
        expect_enqueued_mail_jobs(count: 1) { subject.reject }
      end

      it "does not send email if email is blank" do
        person.update(email: nil)
        expect_no_enqueued_mail_jobs { subject.reject }
      end
    end
  end

  context "Course" do
    let(:group) { groups(:bottom_layer_one) }
    let(:event) { Fabricate(:course, groups: [group]) }

    let(:request) do
      Person::AddRequest::Event.create!(
        person: person,
        requester: requester,
        body: event,
        role_type: role_type.sti_name)
    end

    before do
      Fabricate(:event_question, event: event)
      Fabricate(:event_question, event: event)
      event.reload
    end

    context "participant" do
      let(:role_type) { Event::Course::Role::Participant }

      it "creates a new participation" do
        expect do
          subject.approve
        end.to change { Event::Participation.count }.by(1)

        p = person.event_participations.first
        expect(p).to be_active
        expect(p.roles.count).to eq(1)
        expect(p.roles.first).to be_a(role_type)
        expect(p.answers.count).to eq(2)
        expect(p.application).to be_present
        expect(p.application.priority_1).to eq event
      end

      it "does nothing if role already exists" do
        p = Fabricate(:event_participation,
          event: event,
          person: person,
          active: false,
          application: Fabricate(:event_application, priority_1: event))
        Fabricate(role_type.name, participation: p)

        expect do
          expect(subject.approve).to eq(true)
        end.not_to change { Event::Participation.count }

        p = person.event_participations.first
        expect(p).not_to be_active
        expect(p.roles.count).to eq(1)
        expect(p.roles.first).to be_a(role_type)
        expect(p.answers.count).to eq(2)
        expect(p.application).to be_present
      end
    end

    context "leader" do
      let(:role_type) { Event::Role::Leader }

      it "creates a new participation" do
        expect do
          subject.approve
        end.to change { Event::Participation.count }.by(1)

        p = person.event_participations.first
        expect(p).to be_active
        expect(p.roles.count).to eq(1)
        expect(p.roles.first).to be_a(role_type)
        expect(p.answers.count).to eq(2)
        expect(p.application).to be_nil
      end

      it "creates second role if participation already exists" do
        p = Fabricate(:event_participation, event: event, person: person, active: true)
        Fabricate(Event::Role::Cook.name, participation: p)

        expect do
          expect(subject.approve).to eq(true)
        end.not_to change { Event::Participation.count }

        p = person.event_participations.first
        expect(p).to be_active
        expect(p.roles.count).to eq(2)
        expect(p.roles.last).to be_a(role_type)
        expect(p.answers.count).to eq(2)
        expect(p.application).to be_nil
      end

      it "does nothing if role already exists" do
        p = Fabricate(:event_participation, event: event, person: person, active: true)
        Fabricate(role_type.name, participation: p)

        expect do
          expect(subject.approve).to eq(true)
        end.not_to change { Event::Participation.count }

        p = person.event_participations.first
        expect(p).to be_active
        expect(p.roles.count).to eq(1)
        expect(p.roles.first).to be_a(role_type)
        expect(p.answers.count).to eq(2)
        expect(p.application).to be_nil
      end
    end
  end
end
