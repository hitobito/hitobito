# encoding: utf-8

#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require 'spec_helper'

describe Event::ParticipationConfirmationJob do

  let(:course) { Fabricate(:course, groups: [groups(:top_layer)], priorization: true) }

  let(:participation) do
    Fabricate(:event_participation,
              event: course,
              person: participant,
              application: Fabricate(:event_application,
                                     priority_2: Fabricate(:course, kind: course.kind)))
  end

  let(:person)  { Fabricate(:person, email: 'anybody@example.com') }
  let(:app1)    { Fabricate(:person, email: 'approver1@example.com') }
  let(:app2)    { Fabricate(:person, email: 'approver2@example.com') }

  before do
    SeedFu.quiet = true
    SeedFu.seed [Rails.root.join('db', 'seeds')]

    # create one person with two approvers
    Fabricate(Group::BottomLayer::Leader.name.to_sym, person: app1, group: groups(:bottom_layer_one))
    Fabricate(Group::BottomLayer::Leader.name.to_sym, person: app2, group: groups(:bottom_layer_one))
    Fabricate(Group::BottomGroup::Leader.name.to_sym, person: person, group: groups(:bottom_group_one_one))
  end

  subject { Event::ParticipationConfirmationJob.new(participation) }


  context "without approvers" do
    let(:participant) { people(:top_leader) }

    context "without requiring approval" do
      it "sends confirmation email" do
        course.update_column(:requires_approval, false)
        subject.perform

        ActionMailer::Base.deliveries.should have(1).item
        last_email.subject.should == 'Bestätigung der Anmeldung'
      end
    end

    context "with event requiring approval" do
      it "sends confirmation email" do
        course.update_column(:requires_approval, true)
        subject.perform

        ActionMailer::Base.deliveries.should have(1).item
        last_email.subject.should == 'Bestätigung der Anmeldung'
      end
    end
  end

  context "with approvers" do
    let(:participant) { person }

    context "without requiring approval" do
      it "does not send approval if not required" do
        course.update_column(:requires_approval, false)
        subject.perform

        ActionMailer::Base.deliveries.should have(1).items
        last_email.subject.should == 'Bestätigung der Anmeldung'
      end
    end

    context "with event requiring approval" do
      it "sends confirmation and approvals to approvers" do
        course.update_column(:requires_approval, true)
        subject.perform

        ActionMailer::Base.deliveries.should have(2).items

        first_email = ActionMailer::Base.deliveries.first
        last_email.to.to_set.should == [app1.email, app2.email].to_set
        last_email.subject.should == 'Freigabe einer Kursanmeldung'
        first_email.subject.should == 'Bestätigung der Anmeldung'
      end

      context "with affiliate role in different group with own approvers" do
        it "only sends to group approvers where role is non-affiliate" do
          Fabricate(Group::BottomLayer::Leader.name.to_sym,group: groups(:bottom_layer_two))
          Fabricate(Group::BottomGroup::Leader.name.to_sym, person: person, group: groups(:bottom_group_two_one), deleted_at: 1.year.ago)
          Fabricate(Role::External.name.to_sym, person: person, group: groups(:bottom_group_two_one))

          course.update_column(:requires_approval, true)
          subject.perform

          ActionMailer::Base.deliveries.should have(2).items

          first_email = ActionMailer::Base.deliveries.first
          last_email.to.to_set.should == [app1.email, app2.email].to_set
        end
      end
    end
  end

end
