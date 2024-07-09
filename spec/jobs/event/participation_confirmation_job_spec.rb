#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "spec_helper"

describe Event::ParticipationConfirmationJob do
  CONFIRMATION_SUBJECT = "Bestätigung der Anmeldung"
  PENDING_CONFIRMATION_SUBJECT = "Voranmeldung eingegangen"
  APPROVAL_SUBJECT = "Freigabe einer Kursanmeldung"

  let(:course) { Fabricate(:course, groups: [groups(:top_layer)], priorization: true) }

  let(:participation_active) { false }

  let(:participation) do
    Fabricate(:event_participation,
      event: course,
      active: participation_active,
      person: participant,
      application: Fabricate(:event_application,
        priority_2: Fabricate(:course, kind: course.kind)))
  end

  let(:participant) { person }
  let(:person) { Fabricate(:person, email: "anybody@example.com") }
  let(:app1) { Fabricate(:person, email: "approver1@example.com") }
  let(:app2) { Fabricate(:person, email: "approver2@example.com") }

  before do
    SeedFu.quiet = true
    SeedFu.seed [Rails.root.join("db", "seeds")]

    # create one person with two approvers
    Fabricate(Group::BottomLayer::Leader.name.to_sym, person: app1, group: groups(:bottom_layer_one))
    Fabricate(Group::BottomLayer::Leader.name.to_sym, person: app2, group: groups(:bottom_layer_one))
    Fabricate(Group::BottomGroup::Leader.name.to_sym, person: person, group: groups(:bottom_group_one_one))
  end

  subject { Event::ParticipationConfirmationJob.new(participation) }

  context "for active participation" do
    let(:participation_active) { true }

    it "sends participation confirmation and approval" do
      subject.perform

      expect(ActionMailer::Base.deliveries.size).to eq(2)
      expect(ActionMailer::Base.deliveries.map(&:subject)).to match_array([CONFIRMATION_SUBJECT,
        APPROVAL_SUBJECT])
    end

    it "sends participation confirmation for participation without application entry" do
      participation.application.destroy!

      subject.perform

      expect(ActionMailer::Base.deliveries.size).to eq(2)
      expect(ActionMailer::Base.deliveries.map(&:subject)).to match_array([CONFIRMATION_SUBJECT,
        APPROVAL_SUBJECT])
    end
  end

  context "with approvers" do
    context "without requiring approval" do
      it "does not send approval if not required" do
        course.update_column(:requires_approval, false)
        subject.perform

        expect(ActionMailer::Base.deliveries.size).to eq(1)
        expect(last_email.subject).to eq(PENDING_CONFIRMATION_SUBJECT)
      end
    end

    context "with event requiring approval" do
      it "sends confirmation and approvals to approvers" do
        course.update_column(:requires_approval, true)
        subject.perform

        expect(ActionMailer::Base.deliveries.size).to eq(2)

        first_email = ActionMailer::Base.deliveries.first
        expect(last_email.to.to_set).to eq([app1.email, app2.email].to_set)
        expect(last_email.subject).to eq(APPROVAL_SUBJECT)
        expect(first_email.subject).to eq(PENDING_CONFIRMATION_SUBJECT)
      end

      it "sends approval for active participation" do
        course.update_column(:requires_approval, true)
        participation.update(active: true)
        subject.perform

        first_email = ActionMailer::Base.deliveries.first
        expect(last_email.to.to_set).to eq([app1.email, app2.email].to_set)
        expect(last_email.subject).to eq(APPROVAL_SUBJECT)
        expect(first_email.subject).to eq(CONFIRMATION_SUBJECT)
      end

      it "sends approval for passive participation" do
        course.update_column(:requires_approval, true)
        participation.update(active: false)
        subject.perform

        first_email = ActionMailer::Base.deliveries.first
        expect(last_email.to.to_set).to eq([app1.email, app2.email].to_set)
        expect(last_email.subject).to eq(APPROVAL_SUBJECT)
        expect(first_email.subject).to eq(PENDING_CONFIRMATION_SUBJECT)
      end

      it "does not send approval for participation with approved application" do
        course.update_column(:requires_approval, true)
        participation.application.toggle_approval(true)
        subject.perform

        expect(ActionMailer::Base.deliveries.size).to eq(1)

        expect(last_email.to.to_set).to eq([person.email].to_set)
        expect(last_email.subject).to eq(PENDING_CONFIRMATION_SUBJECT)
      end

      it "does only send confirmation but not approvals to approvers if send_approval false" do
        course.update_column(:requires_approval, true)
        job = Event::ParticipationConfirmationJob.new(participation, send_approval: false)
        job.perform

        expect(ActionMailer::Base.deliveries.size).to eq(1)

        first_email = ActionMailer::Base.deliveries.first
        expect(first_email.subject).to eq(PENDING_CONFIRMATION_SUBJECT)
      end

      context "with external role in different group with own approvers" do
        it "only sends to group approvers where role is non-external" do
          Fabricate(Group::BottomLayer::Leader.name.to_sym, group: groups(:bottom_layer_two))
          Fabricate(Group::BottomGroup::Leader.name.to_sym, person: person, group: groups(:bottom_group_two_one), created_at: 2.years.ago, deleted_at: 1.year.ago)
          Fabricate(Role::External.name.to_sym, person: person, group: groups(:bottom_group_two_one))

          course.update_column(:requires_approval, true)
          subject.perform

          expect(ActionMailer::Base.deliveries.size).to eq(2)

          expect(last_email.to.to_set).to eq([app1.email, app2.email].to_set)
        end
      end
    end
  end
end
