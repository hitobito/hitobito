# encoding: utf-8

# == Schema Information
#
# Table name: event_roles
#
#  id               :integer          not null, primary key
#  type             :string           not null
#  participation_id :integer          not null
#  label            :string
#

#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.
require "spec_helper"

describe Event::Role do
  [Event, Event::Course].each do |event_type|
    event_type.role_types.each do |part|
      context part do
        it "must have valid permissions" do
          # although it looks like, this example is about participation.permissions and not about Participation::Permissions
          expect(Event::Role::Permissions).to include(*part.permissions)
        end
      end
    end
  end

  context "save together with participation" do
    let(:course) do
      course = Fabricate(:course, groups: [groups(:top_layer)], kind: event_kinds(:slk))
      course.questions << Fabricate(:event_question, event: course, required: true)
      course.questions << Fabricate(:event_question, event: course)
      course
    end

    it "validates answers" do
      q = course.questions
      role = Event::Role::Participant.new
      role.participation = course.participations.new(person: Person.first)
      role.participation.enforce_required_answers = true
      role.participation.init_answers
      role.participation.attributes = {
        answers_attributes: [{question_id: q[1].id, answer: "ja"}]}
      expect(role.save).to be_falsey
      expect(role.errors.full_messages).to eq(["Antwort muss ausgefüllt werden"])
    end

    it "refreshes participant_count when updating role" do
      role = Event::Course::Role::Participant.new
      role.participation = course.participations.new(person: Person.first, active: true)
      expect(role.save).to eq true
      expect(course.reload.participant_count).to eq 1
      expect do
        expect(role.update(type: "Event::Course::Role::Leader")).to eq true
      end.to change { course.reload.participant_count }.by(-1)
    end
  end

  context "destroying roles" do
    before do
      @role = Event::Role::Participant.new
      @role.participation = participation
      @role.save!
    end

    let(:event) { events(:top_event) }
    let(:role) { @role.reload }
    let(:participation) { Fabricate(:event_participation, event: event, active: true) }

    it "decrements event#(representative_)participant_count" do
      event.reload
      participant_count = event.participant_count
      applicant_count = event.applicant_count

      role.destroy

      event.reload
      expect(event.participant_count).to eq participant_count - 1
      expect(event.applicant_count).to eq applicant_count - 1
    end

    it "decrements event#participant_count if participations has other non participant roles" do
      treasurer = Event::Role::Treasurer.new
      treasurer.participation = Fabricate(:event_participation, event: event, active: true)
      treasurer.save!

      event.reload
      participant_count = event.participant_count
      applicant_count = event.applicant_count

      role.destroy

      event.reload
      expect(event.participant_count).to eq participant_count - 1
      expect(event.applicant_count).to eq applicant_count - 1
    end

    it "destroys participation if it was the last role" do
      expect do
        event_roles(:top_leader).destroy
      end.to change { Event::Participation.count }.by(-1)
    end
  end
end
