# frozen_string_literal: true

#  Copyright (c) 2026, Berner Fachhochschule. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "spec_helper"

describe Event::ApiRegistration do
  let(:event) { events(:top_event) }
  let(:attrs) { {first_name: "Anna", last_name: "Muster", email: "anna@example.com"} }

  subject(:registration) { described_class.new(event:, **attrs) }

  before do
    event.update_columns(external_applications: true, application_opening_at: nil,
      application_closing_at: nil, maximum_participants: nil)
  end

  def errors_of(registration)
    registration.valid?
    registration.errors.details.transform_values { |details| details.pluck(:error) }
  end

  describe "validation" do
    it "is valid for an open event" do
      expect(registration).to be_valid
    end

    it "requires external applications" do
      event.update_columns(external_applications: false)
      expect(errors_of(registration)).to include(base: [:event_not_open])
    end

    it "requires an open application period" do
      event.update_columns(application_closing_at: Date.yesterday)
      expect(errors_of(registration)).to include(base: [:event_not_open])
    end

    it "requires a place" do
      event.update_columns(maximum_participants: 1, participant_count: 1)
      expect(errors_of(registration)).to include(base: [:event_full])
    end

    it "follows the rules of the event type for applications" do
      allow(event).to receive(:application_possible?).and_return(false)
      expect(errors_of(registration)).to include(base: [:event_not_open])
    end

    it "collects person and answer errors" do
      Fabricate(:event_question, event:, required: true)
      attrs.delete(:last_name)
      expect(errors_of(registration)).to include(last_name: [:blank], answers: [:required])
    end

    it "names attributes like people" do
      expect(described_class.human_attribute_name(:last_name)).to eq "Nachname"
      expect(described_class.human_attribute_name(:answers)).to eq "Antworten"
    end
  end

  describe "#save" do
    it "creates a person and an active participation" do
      question = Fabricate(:event_question, event:, choices: "Ja,Nein")
      attrs[:answers] = [{question_id: question.id, answer: 0}]

      expect { expect(registration.save).to be true }
        .to change { Person.count }.by(1)
        .and change { event.participations.count }.by(1)

      person = Person.find_by(email: "anna@example.com")
      participation = event.participations.find_by(participant: person)
      expect(participation).to be_active
      expect(participation.roles.map(&:class)).to eq [Event::Role::Participant]
      expect(participation.answers.find_by(question:).answer).to eq "Ja"
      expect(person.roles).to be_empty
      expect(registration.registration_status).to eq "participant"
      expect(registration.id).to be_present
    end

    it "registers an existing person without changing it" do
      person = people(:bottom_member)
      attrs.merge!(email: person.email, first_name: person.first_name, last_name: "Neu")

      expect { registration.save }.not_to change { Person.count }

      participation = event.participations.find_by(participant: person)
      expect(participation.additional_information).to be_blank
      expect(person.reload.last_name).to eq "Member"
      expect(registration.registration_status).to eq "participant"
    end

    context "with updatable attributes" do
      let(:person) { people(:bottom_member) }

      around do |example|
        Event::ApiRegistration::Applicant.updatable_attributes = [:town, :last_name]
        example.run
      ensure
        Event::ApiRegistration::Applicant.updatable_attributes = []
      end

      it "overwrites them on an existing person" do
        attrs.merge!(email: person.email, first_name: "Anders", last_name: "Neu", town: "Thun")

        expect(registration.save).to be true
        expect(person.reload).to have_attributes(first_name: "Bottom", last_name: "Neu", town: "Thun")
      end

      it "leaves an existing registration unchanged" do
        Fabricate(:event_participation, event:, participant: person, active: true)
        attrs.merge!(email: person.email, first_name: person.first_name, last_name: "Neu")

        expect(registration.save).to be true
        expect(person.reload.last_name).to eq "Member"
      end
    end

    it "succeeds without changes for an existing registration" do
      person = people(:bottom_member)
      existing = Fabricate(:event_participation, event:, participant: person, active: true)
      attrs.merge!(email: person.email, first_name: person.first_name, last_name: person.last_name)

      expect { expect(registration.save).to be true }
        .not_to change { Event::Participation.count }
      expect(registration.participation).to eq existing
      expect(registration.registration_status).to eq "participant"
    end

    it "reports records failing to save instead of raising" do
      allow_any_instance_of(Person).to receive(:save).and_return(false)

      expect(registration.save).to be false
      expect(registration.participation).to be_nil
      expect(event.participations.joins("INNER JOIN people ON people.id = participant_id")
        .where(people: {email: "anna@example.com"})).to be_empty
    end

    it "creates nothing when invalid" do
      attrs.delete(:email)
      expect { expect(registration.save).to be false }.not_to change { Person.count }
    end

    describe "follow-up jobs" do
      def enqueued(job_class)
        Delayed::Job.where(Delayed::Job.arel_table[:handler].matches("%#{job_class}%")).count
      end

      def expect_jobs(confirmation:, notification:, duplicates:)
        expect { registration.save }
          .to change { enqueued("ParticipationConfirmationJob") }.by(confirmation)
          .and change { enqueued("ParticipationNotificationJob") }.by(notification)
          .and change { enqueued("DuplicateLocatorJob") }.by(duplicates)
      end

      it "confirms, notifies and checks a new person for duplicates" do
        expect_jobs(confirmation: 1, notification: 1, duplicates: 1)
      end

      it "skips notification and duplicate check when turned off" do
        described_class.notify_contact = false
        described_class.locate_duplicates = false
        expect_jobs(confirmation: 1, notification: 0, duplicates: 0)
      ensure
        described_class.notify_contact = true
        described_class.locate_duplicates = true
      end

      it "skips the confirmation if not wanted" do
        attrs[:send_confirmation] = false
        expect_jobs(confirmation: 0, notification: 1, duplicates: 1)
      end

      it "does not check existing people for duplicates" do
        person = people(:bottom_member)
        attrs.merge!(email: person.email, first_name: person.first_name, last_name: person.last_name)
        expect_jobs(confirmation: 1, notification: 1, duplicates: 0)
      end

      it "enqueues nothing for an existing registration" do
        person = people(:bottom_member)
        Fabricate(:event_participation, event:, participant: person, active: true)
        attrs.merge!(email: person.email, first_name: person.first_name, last_name: person.last_name)
        expect_jobs(confirmation: 0, notification: 0, duplicates: 0)
      end

      it "confirms only once when a course place is assigned directly" do
        course = events(:top_course)
        course.update_columns(external_applications: true, application_opening_at: nil,
          application_closing_at: nil, automatic_assignment: true, maximum_participants: nil)
        registration.event = course
        expect_jobs(confirmation: 1, notification: 1, duplicates: 1)
      end
    end

    context "for a course" do
      let(:event) { events(:top_course) }

      before { event.update_columns(automatic_assignment: false, waiting_list: false) }

      it "creates a pending application" do
        expect(registration.save).to be true
        expect(registration.participation).not_to be_active
        expect(registration.participation.application).to be_present
        expect(registration.registration_status).to eq "pending"
      end

      it "assigns the place directly with automatic assignment" do
        event.update_columns(automatic_assignment: true)
        expect(registration.save).to be true
        expect(registration.participation.reload).to be_active
        expect(registration.registration_status).to eq "participant"
      end

      it "puts the person on the waiting list when the course is full" do
        event.update_columns(waiting_list: true, maximum_participants: 1, participant_count: 1)
        expect(registration.save).to be true
        expect(registration.registration_status).to eq "waiting_list"
      end
    end
  end
end
