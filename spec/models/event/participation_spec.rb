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
#  event_id               :integer          not null
#  person_id              :integer          not null
#  additional_information :text
#  created_at             :datetime
#  updated_at             :datetime
#  active                 :boolean          default(FALSE), not null
#  application_id         :integer
#  qualified              :boolean
#

require "spec_helper"

describe Event::Participation do

  let(:course) do
    course = Fabricate(:course, groups: [groups(:top_layer)], kind: event_kinds(:slk))
    course.questions << Fabricate(:event_question, event: course, required: true)
    course.questions << Fabricate(:event_question, event: course)
    course
  end

  context "#init_answers" do
    subject { course.participations.new }

    it "creates answers from event" do
      subject.init_answers
      expect(subject.answers.collect(&:question).to_set).to eq(course.questions.to_set)
    end

    it "creates missing answers" do
      subject.answers_attributes = [{ question_id: course.questions.first.id, answer: "Foo" }]
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
    subject { course.participations.new }

    it "assigns application and answers for new record" do
      q = course.questions
      subject.person_id = 42
      subject.attributes = {
        additional_information: "bla",
        application_attributes: { priority_2_id: 42 },
        answers_attributes: [{ question_id: q[0].id, answer: "ja" },
                             { question_id: q[1].id, answer: "nein" }]
      }

      expect(subject.additional_information).to eq("bla")
      expect(subject.answers.size).to eq(2)
    end

    it "assigns participation and answers for persisted record" do
      p = Person.first
      subject.person = p
      subject.save!

      expect(subject.answers.size).to eq(2)

      q = course.questions
      subject.attributes = {
        additional_information: "bla",
        application_attributes: { priority_2_id: 42 },
        answers_attributes: [{ question_id: q[0].id, answer: "ja", id: subject.answers.first.id },
                             { question_id: q[1].id, answer: "nein", id: subject.answers.last.id }]
      }

      expect(subject.person_id).to eq(p.id)
      expect(subject.additional_information).to eq("bla")
      expect(subject.answers.size).to eq(2)
    end
  end

  context "save together with role" do
    subject { course.participations.new }

    it "validates answers" do
      q = course.questions
      subject.enforce_required_answers = true
      subject.person_id = Person.first.id
      subject.init_answers
      subject.attributes = {
        answers_attributes: [{ question_id: q[1].id, answer: "ja" }]
      }
      subject.roles.new(type: Event::Course::Role::Participant.sti_name)
      expect(subject.save).to be_falsey
      expect(subject.errors.full_messages).to eq(["Antwort muss ausgefüllt werden"])
    end
  end

  context "#destroy" do
    it "destroy roles as well" do
      expect do
        event_participations(:top).destroy
      end.to change { Event::Role.count }.by(-1)
    end
  end

  context "waiting_list?" do
    subject { course.participations.new }

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
      order_clause = Event::Participation.order_by_role_statement(event_type)
      expect(order_clause).to eq "CASE event_roles.type WHEN 'Event::Role::Leader' " \
        "THEN 0 WHEN 'Event::Role::Participant' THEN 1 END"
    end

    it ".order_by_role_statement returns empty string when event has no role_types" do
      event_type = double("event_type", role_types: [])
      order_clause = Event::Participation.order_by_role_statement(event_type)
      expect(order_clause).to eq ""
    end
  end
end
