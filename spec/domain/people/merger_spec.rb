# frozen_string_literal: true

#  Copyright (c) 2024-2024, Puzzle ITC. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "spec_helper"

describe People::Merger do
  let!(:person) { Fabricate(:person) }
  let!(:duplicate) { Fabricate(:person_with_address_and_phone) }
  let(:actor) { people(:root) }
  let(:group) { groups(:bottom_group_one_one) }

  let(:merger) { described_class.new(@source.reload, @target.reload, actor) }

  before do
    Group::BottomGroup::Member.create!(group: group, person: duplicate)
  end

  context "merge people" do
    before do
      @source = duplicate
      @target = person
    end

    it "copies attributes, removes source person, creates log entry" do
      orig_nickname = person.nickname
      orig_first_name = person.first_name
      orig_last_name = person.last_name
      orig_email = person.email
      duplicate_first_name = duplicate.first_name

      expect do
        merger.merge!
      end.to change(Person, :count).by(-1)

      person.reload
      expect(person.nickname).to eq(orig_nickname)
      expect(person.first_name).to eq(orig_first_name)
      expect(person.last_name).to eq(orig_last_name)
      expect(person.email).to eq(orig_email)
      expect(person.address).to eq(duplicate.address)
      expect(person.town).to eq(duplicate.town)
      expect(person.zip_code).to eq(duplicate.zip_code)
      expect(person.country).to eq(duplicate.country)

      expect(Person.where(id: duplicate.id)).not_to exist

      log_hash = YAML.load(person.versions.first.object_changes) # rubocop:disable Security/YAMLLoad
      expect(log_hash).to include(:last_name)
      expect(log_hash).not_to include(:id)
      expect(log_hash).not_to include(:primary_group_id)
      expect(log_hash[:first_name]).not_to eq person.first_name
      expect(log_hash[:first_name]).to eq duplicate_first_name
      expect(log_hash[:roles].first).to eq("Member (Bottom One / Group 11)")
    end

    it "merges roles, phone numbers and e-mail addresses" do
      Group::BottomGroup::Member.create!(group: groups(:bottom_group_two_one),
        person: person)

      expect do
        merger.merge!
      end.to change(Person, :count).by(-1)

      person.reload

      person_roles = person.roles.with_inactive
      expect(person_roles.count).to eq(2)
      group_ids = person_roles.map(&:group_id)
      expect(group_ids).to include(group.id)
      expect(group_ids).to include(groups(:bottom_group_two_one).id)

      expect(Person.where(id: duplicate.id)).not_to exist
    end

    it "merges invoices" do
      target_invoice_1 = Fabricate(:invoice, group: group, recipient: person)
      source_invoice_1 = Fabricate(:invoice, group: group, recipient: duplicate)
      source_invoice_2 = Fabricate(:invoice, group: group, recipient: duplicate)

      expect do
        merger.merge!
      end.to change(Person, :count).by(-1)
        .and not_change { Invoice.count }

      person.reload
      expect(person.invoices.count).to eq 3
      expect(target_invoice_1.reload.recipient).to eq person
      expect(source_invoice_1.reload.recipient).to eq person
      expect(source_invoice_2.reload.recipient).to eq person
    end

    context "notes" do
      let!(:target_note_1) { Fabricate(:note, author: person, subject: person) }
      let!(:source_note_1) { Fabricate(:note, author: duplicate, subject: duplicate) }
      let!(:source_note_2) { Fabricate(:note, author: duplicate, subject: duplicate) }

      it "merges notes" do
        expect do
          merger.merge!
        end.to change(Person, :count).by(-1)
          .and not_change { Note.count }

        person.reload
        expect(person.notes.count).to eq 3
        expect(target_note_1.reload.subject).to eq person
        expect(source_note_1.reload.subject).to eq person
        expect(source_note_2.reload.subject).to eq person
      end

      it "merges authored_notes" do
        expect do
          merger.merge!
        end.to change(Person, :count).by(-1)
          .and not_change { Note.count }

        person.reload
        expect(person.authored_notes.count).to eq 3
        expect(target_note_1.reload.author).to eq person
        expect(source_note_1.reload.author).to eq person
        expect(source_note_2.reload.author).to eq person
      end
    end

    it "merges event_responsibilities" do
      target_event_1 = Fabricate(:event, contact: person)
      source_event_1 = Fabricate(:event, contact: duplicate)
      source_event_2 = Fabricate(:event, contact: duplicate)

      expect do
        merger.merge!
      end.to change(Person, :count).by(-1)
        .and change(person.event_responsibilities, :count).by(2)

      person.reload
      expect(person.event_responsibilities.count).to eq 3
      expect(target_event_1.reload.contact).to eq person
      expect(source_event_1.reload.contact).to eq person
      expect(source_event_2.reload.contact).to eq person
    end

    it "merges group_responsibilities" do
      target_group_1 = Fabricate(Group::TopGroup.sti_name, parent: Group.root)
      source_group_1 = Fabricate(Group::TopGroup.sti_name, parent: Group.root)
      source_group_2 = Fabricate(Group::TopGroup.sti_name, parent: Group.root)

      Fabricate(Group::TopGroup::Leader.sti_name, person: person, group: target_group_1)
      Fabricate(Group::TopGroup::Leader.sti_name, person: duplicate, group: source_group_1)
      Fabricate(Group::TopGroup::Leader.sti_name, person: duplicate, group: source_group_2)

      target_group_1.update!(contact: person)
      source_group_1.update!(contact: duplicate)
      source_group_2.update!(contact: duplicate)

      expect do
        merger.merge!
      end.to change(Person, :count).by(-1)
        .and change(person.group_responsibilities, :count).by(2)

      person.reload
      expect(person.group_responsibilities.count).to eq 3
      expect(target_group_1.reload.contact).to eq person
      expect(source_group_1.reload.contact).to eq person
      expect(source_group_2.reload.contact).to eq person
    end

    it "merges family_members" do
      target_family_member_1 = Fabricate(:family_member, person: person)
      source_family_member_1 = Fabricate(:family_member, person: duplicate)
      source_family_member_2 = Fabricate(:family_member, person: duplicate)

      expect do
        merger.merge!
      end.to change(Person, :count).by(-1)
        .and not_change { FamilyMember.count }

      person.reload
      expect(person.family_members.count).to eq 3
      expect(target_family_member_1.reload.person).to eq person
      expect(source_family_member_1.reload.person).to eq person
      expect(source_family_member_2.reload.person).to eq person
    end

    it "does not merge family member when target already has family member relation to the same person" do
      Fabricate(:family_member, person: person, other: Person.root)
      Fabricate(:family_member, person: duplicate, other: Person.root)

      # destroy automaitcally created family member record to be able to test this case
      duplicate.family_members.last.destroy!

      expect do
        merger.merge!
      end.to change(Person, :count).by(-1)
        .and change(person.family_members, :count).by(0)

      expect(person.reload.family_members.count).to eq 1
    end

    it "merges tags" do
      target_tag_1 = person.tags.create!(name: "AAA").taggings.first
      source_tag_1 = duplicate.tags.create!(name: "BBB").taggings.first
      source_tag_2 = duplicate.tags.create!(name: "CCC").taggings.first

      expect do
        merger.merge!
      end.to change(Person, :count).by(-1)
        .and not_change { ActsAsTaggableOn::Tagging.count }

      person.reload
      expect(person.tags.count).to eq 3
      expect(target_tag_1.reload.taggable).to eq person
      expect(source_tag_1.reload.taggable).to eq person
      expect(source_tag_2.reload.taggable).to eq person
    end

    it "does not merge tags when target already has certain tag" do
      tag = Fabricate(:tag)

      person.taggings.create!(tag: tag, context: "Person")
      duplicate.taggings.create!(tag: tag, context: "Person")

      expect do
        merger.merge!
      end.to change(Person, :count).by(-1)
        .and change(person.taggings, :count).by(0)

      expect(person.reload.taggings.count).to eq 1
    end

    it "merges qualifications" do
      target_qualification_1 = Fabricate(:qualification, person: person)
      source_qualification_1 = Fabricate(:qualification, person: duplicate)
      source_qualification_2 = Fabricate(:qualification, person: duplicate)

      expect do
        merger.merge!
      end.to change(Person, :count).by(-1)
        .and not_change { Qualification.count }

      person.reload
      expect(person.qualifications.count).to eq 3
      expect(target_qualification_1.reload.person).to eq person
      expect(source_qualification_1.reload.person).to eq person
      expect(source_qualification_2.reload.person).to eq person
    end

    it "does not merge extra qualification when target already has qualification of certain kind" do
      Fabricate(:qualification, person: person, qualification_kind: QualificationKind.first, start_at: 10.days.ago)
      Fabricate(:qualification, person: duplicate, qualification_kind: QualificationKind.first, start_at: 10.days.ago)

      expect do
        merger.merge!
      end.to change(Person, :count).by(-1)
        .and change(person.qualifications, :count).by(0)

      expect(person.reload.qualifications.count).to eq 1
    end

    it "does merge qualification when target already has qualification of certain kind but in different time" do
      target_qualification = Fabricate(:qualification, person: person, qualification_kind: QualificationKind.first, start_at: 10.days.ago)
      source_qualification = Fabricate(:qualification, person: duplicate, qualification_kind: QualificationKind.second, start_at: 30.days.ago)

      expect do
        merger.merge!
      end.to change(Person, :count).by(-1)
        .and change(person.qualifications, :count).by(1)

      person.reload
      expect(person.qualifications.count).to eq 2
      expect(target_qualification.reload.person).to eq person
      expect(source_qualification.reload.person).to eq person
    end

    it "merges subscriptions" do
      target_subscription_1 = Fabricate(:subscription, mailing_list: MailingList.first, subscriber: person)
      source_subscription_1 = Fabricate(:subscription, mailing_list: MailingList.second, subscriber: duplicate)
      source_subscription_2 = Fabricate(:subscription, mailing_list: MailingList.third, subscriber: duplicate)

      expect do
        merger.merge!
      end.to change(Person, :count).by(-1)
        .and not_change { Subscription.count }

      person.reload
      expect(person.subscriptions.count).to eq 3
      expect(target_subscription_1.reload.subscriber).to eq person
      expect(source_subscription_1.reload.subscriber).to eq person
      expect(source_subscription_2.reload.subscriber).to eq person
    end

    it "does not merge extra subscription when target already has subscription on certain mailing list" do
      Fabricate(:subscription, mailing_list: MailingList.first, subscriber: person)
      Fabricate(:subscription, mailing_list: MailingList.first, subscriber: duplicate)

      expect do
        merger.merge!
      end.to change(Person, :count).by(-1)
        .and change(person.subscriptions, :count).by(0)

      expect(person.reload.subscriptions.count).to eq 1
    end

    it "merges add_requests" do
      target_add_request_1 = Person::AddRequest::Group.create!(person: person, requester: Person.root, role_type: Group.first.role_types.first.sti_name, body_id: Group.first.id)
      source_add_request_1 = Person::AddRequest::Group.create!(person: duplicate, requester: Person.root, role_type: Group.second.role_types.first.sti_name, body_id: Group.second.id)
      source_add_request_2 = Person::AddRequest::Group.create!(person: duplicate, requester: Person.root, role_type: Group.third.role_types.first.sti_name, body_id: Group.third.id)

      expect do
        merger.merge!
      end.to change(Person, :count).by(-1)
        .and not_change { Person::AddRequest::Group.count }

      person.reload
      expect(person.add_requests.count).to eq 3
      expect(target_add_request_1.reload.person).to eq person
      expect(source_add_request_1.reload.person).to eq person
      expect(source_add_request_2.reload.person).to eq person
    end

    it "does not merge extra add_requests when target already has add_request in certain group/event" do
      Person::AddRequest::Group.create!(person: person, requester: Person.root, role_type: Group.first.role_types.first.sti_name, body_id: Group.first.id)
      Person::AddRequest::Group.create!(person: duplicate, requester: Person.root, role_type: Group.first.role_types.first.sti_name, body_id: Group.first.id)

      expect do
        merger.merge!
      end.to change(Person, :count).by(-1)
        .and change(person.add_requests, :count).by(0)

      expect(person.reload.add_requests.count).to eq 1
    end

    it "merges participations" do
      target_participation_1 = Fabricate(:event_participation, participant: person)
      source_participation_1 = Fabricate(:event_participation, participant: duplicate)
      source_participation_2 = Fabricate(:event_participation, participant: duplicate)

      expect do
        merger.merge!
      end.to change(Person, :count).by(-1)
        .and not_change { Event::Participation.count }

      person.reload
      expect(person.event_participations.count).to eq 3
      expect(target_participation_1.reload.person).to eq person
      expect(source_participation_1.reload.person).to eq person
      expect(source_participation_2.reload.person).to eq person
    end

    it "does not merge extra participation when target already has participation in certain event" do
      Fabricate(:event_participation, event: Event.first, participant: person)
      Fabricate(:event_participation, event: Event.first, participant: duplicate)

      expect do
        merger.merge!
      end.to change(Person, :count).by(-1)
        .and change(person.event_participations, :count).by(0)

      expect(person.reload.event_participations.count).to eq 1
    end

    it "merges event_invitations" do
      target_invitation_1 = Fabricate(:event_invitation, person: person)
      source_invitation_1 = Fabricate(:event_invitation, person: duplicate)
      source_invitation_2 = Fabricate(:event_invitation, person: duplicate)

      expect do
        merger.merge!
      end.to change(Person, :count).by(-1)
        .and not_change { Event::Invitation.count }

      person.reload
      expect(person.event_invitations.count).to eq 3
      expect(target_invitation_1.reload.person).to eq person
      expect(source_invitation_1.reload.person).to eq person
      expect(source_invitation_2.reload.person).to eq person
    end

    it "does not merge extra event_invitation when target already has invitation in certain event" do
      Fabricate(:event_invitation, event: Event.first, person: person)
      Fabricate(:event_invitation, event: Event.first, person: duplicate)

      expect do
        merger.merge!
      end.to change(Person, :count).by(-1)
        .and change(person.event_invitations, :count).by(0)

      expect(person.reload.event_invitations.count).to eq 1
    end

    it "does not merge role if same role already present on destination person" do
      Group::BottomGroup::Member.create!(group: group,
        person: person)

      expect do
        merger.merge!
      end.to change(Person, :count).by(-1)

      person_roles = person.roles.with_inactive
      expect(person_roles.count).to eq(1)
      group_ids = person_roles.map(&:group_id)
      expect(group_ids).to include(group.id)

      expect(Person.where(id: duplicate.id)).not_to exist
    end

    it "does not merge role if same role with different created at already present on destination person" do
      Group::BottomGroup::Member.create!(group: group,
        person: person)

      @source.update(created_at: @source.roles.first.created_at + 3.days)

      expect do
        merger.merge!
      end.to change(Person, :count).by(-1)

      person_roles = person.roles.with_inactive
      expect(person_roles.count).to eq(1)
      group_ids = person_roles.map(&:group_id)
      expect(group_ids).to include(group.id)

      expect(Person.where(id: duplicate.id)).not_to exist
    end

    it "does also merge deleted roles" do
      Group::BottomGroup::Member.create!(group: group,
        person: person)

      _duplicate_two_one_role =
        Group::BottomGroup::Member.create!(group: groups(:bottom_group_two_one),
          person: duplicate, start_on: 1.year.ago, end_on: 1.day.ago)

      # should not merge this deleted role since person has it already
      _duplicate_one_one_role =
        Group::BottomGroup::Member.create!(group: group,
          person: duplicate, start_on: 1.year.ago, end_on: 1.day.ago)

      expect do
        merger.merge!
      end.to change(Person, :count).by(-1)
        .and change { person.roles.with_inactive.count }.by(2) # rubocop:disable Layout/MultilineMethodCallIndentation

      group_ids = person.roles.with_inactive.map(&:group_id)
      expect(group_ids).to include(group.id)
      expect(group_ids).to include(groups(:bottom_group_two_one).id)

      expect(Person.where(id: duplicate.id)).not_to exist
    end

    it "merges additional e-mails" do
      duplicate.additional_emails.create!(email: "first@example.com", label: "Privat")
      duplicate.additional_emails.create!(email: "myadditional@example.com", label: "Other")
      person.additional_emails.create!(email: "myadditional@example.com", label: "Business")

      expect do
        merger.merge!
      end.to change(Person, :count).by(-1)

      person.reload

      expect(person.additional_emails.reload.count).to eq(2)

      expect(Person.where(id: duplicate.id)).not_to exist
    end

    it "merges phone numbers" do
      5.times do
        Fabricate(:phone_number, contactable: duplicate)
      end
      duplicate.phone_numbers.create!(number: "0900 42 42 42", label: "Other")
      person.phone_numbers.create!(number: "0900 42 42 42", label: "Mobile")

      # does not merge invalid contactable
      invalid_contactable = PhoneNumber.new(contactable: duplicate,
        number: "abc 123",
        label: "Holiday")
      invalid_contactable.save!(validate: false)

      expect do
        merger.merge!
      end.to change(Person, :count).by(-1)

      person.reload

      expect(person.phone_numbers.count).to eq(7)

      expect(Person.where(id: duplicate.id)).not_to exist
    end

    it "merges social accounts" do
      Fabricate(:social_account, contactable: duplicate)
      duplicate.social_accounts.create!(name: "john.member", label: "Telegram")

      duplicate.social_accounts.create!(name: "john.member", label: "Signal")
      person.social_accounts.create!(name: "john.member", label: "Signal")

      expect do
        merger.merge!
      end.to change(Person, :count).by(-1)

      person.reload

      expect(person.social_accounts.count).to eq(3)

      expect(Person.where(id: duplicate.id)).not_to exist
    end

    context "households" do
      context "when only source has household" do
        it "adds target to source household" do
          household = @source.household
          household.add(Fabricate(:person_with_address_and_phone))
          household.save!
          expect(@target.household_key).to be_nil

          expect do
            merger.merge!
          end.to change(Person, :count).by(-1)

          expect(@target.household_key).to eq household.household_key
          expect(@target.address).to eq household.reference_person.address
        end
      end

      context "when both have households" do
        it "removes source from its household" do
          source_household = @source.household
          source_household.add(Fabricate(:person_with_address_and_phone))
          source_household.save!

          target_household = @target.household
          target_household.add(Fabricate(:person_with_address_and_phone))
          target_household.save!

          expect do
            merger.merge!
          end.to change(Person, :count).by(-1)

          # "2 people household" was deleted, because one person was removed.
          expect(Person.where(household_key: source_household.household_key).count).to eq 0
        end
      end

      context "when neither has household" do
        it "does not touches households" do
          expect(@source.household_key).to be_nil
          expect(@target.household_key).to be_nil

          expect do
            merger.merge!
          end.to change(Person, :count).by(-1)

          expect(@source.household_key).to be_nil
          expect(@target.household_key).to be_nil
        end
      end
    end

    xit "merges pictures"
  end
end
