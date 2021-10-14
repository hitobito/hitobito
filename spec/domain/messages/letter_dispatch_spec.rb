# frozen_string_literal: true

#  Copyright (c) 2012-2021, Die Mitte. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require 'spec_helper'

describe Messages::LetterDispatch do
  let(:message)    { messages(:letter) }
  let(:top_leader) { people(:top_leader) }
  let(:bottom_member) { people(:bottom_member) }
  let(:recipient_entries) { message.message_recipients }

  subject { described_class.new(message) }

  before do
    Subscription.create!(mailing_list: mailing_lists(:leaders),
                         subscriber: groups(:bottom_layer_one),
                         role_types: [Group::BottomLayer::Member])
    Fabricate(Group::BottomLayer::Member.name, group: groups(:bottom_layer_one), person: top_leader)
  end

  it 'updates success count' do
    subject.run
    expect(message.reload.success_count).to eq 1
  end

  it 'creates recipient entries with address' do
    subject.run

    # does not include top leader because no address present
    expect(message.message_recipients).to_not include(top_leader)

    recipient = recipient_entries.first
    expect(recipient.message).to eq message
    expect(recipient.person).to eq bottom_member
    expect(recipient.address).to eq "Bottom Member\nGreatstreet 345\n3456 Greattown"
  end

  it 'does not duplicate entries if run is called a second time' do
    2.times { subject.run }

    expect(recipient_entries.count).to eq(1)
  end

  context 'household addresses' do

    let(:housemate1) { Fabricate(:person_with_address, first_name: 'Anton', last_name: 'Abraham') }
    let(:housemate2) { Fabricate(:person_with_address, first_name: 'Zora', last_name: 'Zaugg') }
    let(:other_housemate) { Fabricate(:person_with_address, first_name: 'Altra', last_name: 'Mates') }

    before do
      Fabricate(Group::BottomLayer::Member.name, group: groups(:bottom_layer_one), person: housemate1)
      Fabricate(Group::BottomLayer::Member.name, group: groups(:bottom_layer_one), person: housemate2)
    end

    before do
      create_household(housemate1, housemate2)

      # other housemate is not part of member list, so only bottom member should be included without household address
      create_household(people(:bottom_member), other_housemate)

      top_leader.update!(address: 'Fantasia 42', zip_code: '4242', town: 'Melmac')
    end

    it 'does not concern household addresses' do
      subject.run

      expect(recipient_entries.count).to eq(4)
      housemate1_address =
        "#{housemate1.full_name}\n" \
        "#{housemate1.address}\n" \
        "#{housemate1.zip_code} #{housemate1.town}\n" \
        "#{housemate1.country}"

      expect(recipient_entry(housemate1).address).to eq(housemate1_address)

      housemate2_address =
        "#{housemate2.full_name}\n" \
        "#{housemate2.address}\n" \
        "#{housemate2.zip_code} #{housemate2.town}\n" \
        "#{housemate2.country}"

      expect(recipient_entry(housemate2).address).to eq(housemate2_address)

      bottom_member_address =
        "#{bottom_member.full_name}\n" \
        "#{bottom_member.address}\n" \
        "#{bottom_member.zip_code} #{bottom_member.town}\n" \
        "#{bottom_member.country}"
      expect(recipient_entry(bottom_member).address).to eq(bottom_member_address)

      top_leader_address =
        "#{top_leader.full_name}\n" \
        "#{top_leader.address}\n" \
        "#{top_leader.zip_code} #{top_leader.town}\n" \
        "#{top_leader.country}"
      expect(recipient_entry(top_leader).address).to eq(top_leader_address)
    end

    it 'creates recipient entries with household addresses' do
      message.update!(send_to_households: true)

      subject.run

      expect(recipient_entries.count).to eq(4)
      household_address =
        "#{housemate1.full_name}, #{housemate2.full_name}\n" \
        "#{housemate1.address}\n" \
        "#{housemate1.zip_code} #{housemate1.town}\n" \
        "#{housemate1.country}"

      expect(recipient_entry(housemate1).address).to eq(household_address)
      expect(recipient_entry(housemate1).household_address).to eq(true)
      expect(recipient_entry(housemate2).address).to eq(household_address)
      expect(recipient_entry(housemate2).household_address).to eq(true)

      bottom_member_address =
        "#{bottom_member.full_name}\n" \
        "#{bottom_member.address}\n" \
        "#{bottom_member.zip_code} #{bottom_member.town}\n" \
        "#{bottom_member.country}"
      expect(recipient_entry(bottom_member).address).to eq(bottom_member_address)
      expect(recipient_entry(bottom_member).household_address).to eq(false)

      top_leader_address =
        "#{top_leader.full_name}\n" \
        "#{top_leader.address}\n" \
        "#{top_leader.zip_code} #{top_leader.town}\n" \
        "#{top_leader.country}"
      expect(recipient_entry(top_leader).address).to eq(top_leader_address)
      expect(recipient_entry(top_leader).household_address).to eq(false)
    end

    it 'adds all names from household address to address box and sorts them alphabetically' do
      message.update!(send_to_households: true)
      housemate3 = Fabricate(:person_with_address, first_name: 'Mark', last_name: 'Hols')
      housemate4 = Fabricate(:person_with_address, first_name: 'Jana', last_name: 'Nicks')
      housemate5 = Fabricate(:person_with_address, first_name: 'Olivia', last_name: 'Berms')
      Fabricate(Group::BottomLayer::Member.name, group: groups(:bottom_layer_one), person: housemate3)
      Fabricate(Group::BottomLayer::Member.name, group: groups(:bottom_layer_one), person: housemate4)
      Fabricate(Group::BottomLayer::Member.name, group: groups(:bottom_layer_one), person: housemate5)

      create_household(housemate1, housemate3)
      create_household(housemate1, housemate4)
      create_household(housemate1, housemate5)

      subject.run

      address = recipient_entry(housemate2).address.split("\n")
      expect(address).to include('Anton Abraham, Olivia Berms, Mark Hols, Jana Nicks, Zora Zaugg')
    end
  end

  private

  def create_household(person1, person2)
    fake_ability = instance_double('aby', cannot?: false)
    household = Person::Household.new(person1, fake_ability, person2, top_leader)
    household.assign
    household.save
  end

  def recipient_entry(person)
    recipient_entries.find { |e| e.person_id == person.id }
  end
end
