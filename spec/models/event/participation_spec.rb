# frozen_string_literal: true

#  Copyright (c) 20120-2020, Stiftung für junge Auslandssschweizer. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.
# == Schema Information
#
# Table name: event_participations
#
#  id                     :integer          not null, primary key
#  active                 :boolean          default(FALSE), not null
#  additional_information :text
#  participant_type       :string
#  qualified              :boolean
#  created_at             :datetime
#  updated_at             :datetime
#  application_id         :integer
#  event_id               :integer          not null
#  participant_id         :integer          not null
#
# Indexes
#
#  idx_on_participant_type_participant_id_bfb6fab1d7    (participant_type,participant_id)
#  index_event_participations_on_application_id         (application_id)
#  index_event_participations_on_event_id               (event_id)
#  index_event_participations_on_participant_id         (participant_id)
#  index_event_participations_on_polymorphic_and_event  (participant_type,participant_id,event_id) UNIQUE
#
require "spec_helper"

describe Event::Participation do
  let(:course) do
    course = Fabricate(:course, groups: [groups(:top_layer)], kind: event_kinds(:slk))
    course.questions << Fabricate(:event_question, event: course, disclosure: :required)
    course.questions << Fabricate(:event_question, event: course)
    course
  end

  subject { course.participations.new(event: course) }

  context "#init_answers" do
    it "creates answers from event" do
      subject.init_answers
      expect(subject.answers.collect(&:question).to_set).to eq(course.questions.to_set)
    end

    it "creates missing answers" do
      subject.answers_attributes = [{question_id: course.questions.first.id, answer: "Foo"}]
      subject.init_answers

      expect(subject.answers.size).to eq(2)
      expect(subject.answers.first.answer).to eq("Foo")
      expect(subject.answers.last.answer).to be_blank
    end

    it "does not save associations in database" do
      expect { subject.init_answers }.not_to change(Event::Answer, :count)
      expect { subject.init_answers }.not_to change(Event::Participation, :count)
    end
  end

  context "mass assignments" do
    it "assigns application and answers for new record" do
      q = course.questions
      subject.participant_id = 42
      subject.attributes = {
        additional_information: "bla",
        application_attributes: {priority_2_id: 42},
        answers_attributes: [{question_id: q[0].id, answer: "ja"},
          {question_id: q[1].id, answer: "nein"}]
      }

      expect(subject.additional_information).to eq("bla")
      expect(subject.answers.size).to eq(2)
    end

    it "assigns participation and answers for persisted record" do
      p = Person.first
      subject.participant = p
      subject.save!

      expect(subject.answers.size).to eq(2)

      q = course.questions
      subject.attributes = {
        additional_information: "bla",
        application_attributes: {priority_2_id: 42},
        answers_attributes: [{question_id: q[0].id, answer: "ja", id: subject.answers.first.id},
          {question_id: q[1].id, answer: "nein", id: subject.answers.last.id}]
      }

      expect(subject.participant_id).to eq(p.id)
      expect(subject.additional_information).to eq("bla")
      expect(subject.answers.size).to eq(2)
    end
  end

  context "save together with role" do
    it "validates answers" do
      q = course.questions
      subject.enforce_required_answers = true
      subject.participant = Person.first
      subject.init_answers
      subject.attributes = {
        answers_attributes: [{question_id: q[1].id, answer: "ja"}]
      }
      subject.roles.new(type: Event::Course::Role::Participant.sti_name)
      expect(subject.save).to be_falsey
      expect(subject.errors.full_messages).to eq(["Antwort muss ausgefüllt werden"])
    end
  end

  context "#destroy" do
    it "destroys roles as well" do
      expect do
        event_participations(:top).destroy
      end.to change { Event::Role.count }.by(-1)
    end

    it "destroys guest-participants as well" do
      guest_participation = Fabricate(:event_participation, participant: Fabricate(:event_guest))

      expect do
        guest_participation.destroy
      end.to change { Event::Guest.count }.by(-1)
    end

    it "does not destroy person participants" do
      expect do
        event_participations(:top).destroy
      end.to not_change { Person.count }
    end
  end

  context "waiting_list?" do
    it "is true if the application is on the waiting-list" do
      subject.build_application(waiting_list: true)

      expect(subject.application).to be_present
      expect(subject.application.waiting_list).to be_truthy

      is_expected.to be_waiting_list
    end

    it "is false if the application is not on the waiting-list" do
      subject.build_application(waiting_list: false)

      expect(subject.application).to be_present
      expect(subject.application.waiting_list).to be_falsey

      is_expected.to_not be_waiting_list
    end

    it "is false if no application it present" do
      expect(subject.application).to_not be_present

      is_expected.to_not be_waiting_list
    end
  end

  context ".order_by_role_statement" do
    it "orders by index of role_types" do
      event_type = double("event_type", role_types: [Event::Role::Leader, Event::Role::Participant])
      ordered_participations = Event::Participation.order_by_role(event_type)
      expect(ordered_participations.to_sql).to include "ORDER BY event_role_type_orders.order_weight ASC"
    end
  end

  context "validations" do
    let!(:other_participation) { Fabricate(:event_participation, participant: people(:top_leader), event: course) }

    it "validates uniqness of participant" do
      subject.participant = people(:top_leader)
      expect(subject).not_to be_valid
      expect(subject.errors.full_messages).to eq ["Teilnehmer ist bereits vergeben"]
    end

    it "is valid when same id has different type" do
      guest = Fabricate(:event_guest)
      guest.id = people(:top_leader).id
      guest.save(validate: false)
      subject.participant = guest
      expect(subject).to be_valid
    end
  end

  context "#person" do
    it "returns participant when participant_type is person" do
      subject.participant = people(:top_leader)
      expect(subject.person).to eq(people(:top_leader))
    end

    it "returns unpersisted person for built based on event_guest" do
      subject.participant = Fabricate(:event_guest)
      expect(subject.person).not_to be_persisted
      expect(subject.person.first_name).to eq subject.participant.first_name
      expect(subject.person.last_name).to eq subject.participant.last_name
      expect(subject.person.nickname).to eq subject.participant.nickname
      expect(subject.person.email).to eq subject.participant.email
    end
  end
end
