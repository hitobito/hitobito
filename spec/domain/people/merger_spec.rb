# frozen_string_literal: true

require 'spec_helper'

describe People::Merger do

  let!(:person) { Fabricate(:person) }
  let!(:duplicate) { Fabricate(:person_with_address_and_phone) }
  let(:actor) { people(:root) }
  let(:person_roles) { person.roles.with_deleted }

  let(:merger) { described_class.new(@source.reload, @target.reload, actor) }

  before do
    Group::BottomGroup::Member.create!(group: groups(:bottom_group_one_one),
                                       person: duplicate)
  end

  context 'merge people' do

    it 'copies attributes, removes source person, creates log entry' do
      @source = duplicate
      @target = person

      orig_nickname = person.nickname
      orig_first_name = person.first_name
      orig_last_name = person.last_name
      orig_email = person.email

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

      log_hash = YAML.load(person.versions.first.object_changes)
      expect(log_hash).to include(:last_name)
      expect(log_hash).not_to include(:id)
      expect(log_hash).not_to include(:primary_group_id)
      expect(log_hash[:roles].first).to eq('Member (Bottom One / Group 11)')
    end

    it 'merges roles, phone numbers and e-mail addresses' do
      @source = duplicate
      @target = person

      Group::BottomGroup::Member.create!(group: groups(:bottom_group_two_one),
                                         person: person)

      expect do
        merger.merge!
      end.to change(Person, :count).by(-1)

      person.reload

      expect(person_roles.count).to eq(2)
      group_ids = person_roles.map(&:group_id)
      expect(group_ids).to include(groups(:bottom_group_one_one).id)
      expect(group_ids).to include(groups(:bottom_group_two_one).id)

      expect(Person.where(id: duplicate.id)).not_to exist
    end

    it 'does not merge role if same role already present on destination person' do
      @source = duplicate
      @target = person

      Group::BottomGroup::Member.create!(group: groups(:bottom_group_one_one),
                                         person: person)

      expect do
        merger.merge!
      end.to change(Person, :count).by(-1)

      expect(person_roles.count).to eq(1)
      group_ids = person_roles.map(&:group_id)
      expect(group_ids).to include(groups(:bottom_group_one_one).id)

      expect(Person.where(id: duplicate.id)).not_to exist
    end

    it 'does also merge deleted roles' do
      @source = duplicate
      @target = person

      Group::BottomGroup::Member.create!(group: groups(:bottom_group_one_one),
                                         person: person)

      duplicate_two_one_role =
        Group::BottomGroup::Member.create!(group: groups(:bottom_group_two_one),
                                           person: duplicate)

      duplicate_two_one_role.delete
      # check soft delete
      expect(Role.with_deleted.where(id: duplicate_two_one_role.id)).to exist

      # should not merge this deleted role since person has it already
      duplicate_one_one_role =
        Group::BottomGroup::Member.create!(group: groups(:bottom_group_one_one),
                                           person: duplicate)
      duplicate_one_one_role.delete
      # check soft delete
      expect(Role.with_deleted.where(id: duplicate_one_one_role.id)).to exist

      expect do
        merger.merge!
      end.to change(Person, :count).by(-1)

      expect(person_roles.reload.count).to eq(2)
      group_ids = person_roles.map(&:group_id)
      expect(group_ids).to include(groups(:bottom_group_one_one).id)
      expect(group_ids).to include(groups(:bottom_group_two_one).id)

      expect(Person.where(id: duplicate.id)).not_to exist
    end

    it 'merges additional e-mails' do
      @source = duplicate
      @target = person

      duplicate.additional_emails.create!(email: 'first@example.com', label: 'Privat')
      duplicate.additional_emails.create!(email: 'myadditional@example.com', label: 'Other')
      person.additional_emails.create!(email: 'myadditional@example.com', label: 'Business')

      expect do
        merger.merge!
      end.to change(Person, :count).by(-1)

      person.reload

      expect(person.additional_emails.reload.count).to eq(2)

      expect(Person.where(id: duplicate.id)).not_to exist
    end

    it 'merges phone numbers' do
      @source = duplicate
      @target = person

      5.times do
        Fabricate(:phone_number, contactable: duplicate)
      end
      duplicate.phone_numbers.create!(number: '0900 42 42 42', label: 'Other')
      person.phone_numbers.create!(number: '0900 42 42 42', label: 'Mobile')

      # does not merge invalid contactable
      invalid_contactable = PhoneNumber.new(contactable: duplicate,
                                            number: 'abc 123',
                                            label: 'Holiday')
      invalid_contactable.save!(validate: false)

      expect do
        merger.merge!
      end.to change(Person, :count).by(-1)

      person.reload

      expect(person.phone_numbers.count).to eq(7)

      expect(Person.where(id: duplicate.id)).not_to exist
    end

    it 'merges social accounts' do
      @source = duplicate
      @target = person

      Fabricate(:social_account, contactable: duplicate)
      duplicate.social_accounts.create!(name: 'john.member', label: 'Telegram')

      duplicate.social_accounts.create!(name: 'john.member', label: 'Signal')
      person.social_accounts.create!(name: 'john.member', label: 'Signal')

      expect do
        merger.merge!
      end.to change(Person, :count).by(-1)

      person.reload

      expect(person.social_accounts.count).to eq(3)

      expect(Person.where(id: duplicate.id)).not_to exist
    end

  end

end
