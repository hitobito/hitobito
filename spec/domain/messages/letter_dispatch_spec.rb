# frozen_string_literal: true

#  Copyright (c) 2012-2024, Die Mitte. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "spec_helper"

describe Messages::LetterDispatch do
  include Households::SpecHelper

  let(:message) { messages(:letter) }
  let(:top_leader) { people(:top_leader) }
  let(:bottom_member) { people(:bottom_member) }
  let(:recipient_entries) { message.message_recipients }
  let(:default_country) { Settings.countries.prioritized.first }
  let(:not_default_country) do
    code = Faker::Address.country_code until code != default_country
  end

  subject { described_class.new(message) }

  before do
    Subscription.create!(mailing_list: mailing_lists(:leaders),
      subscriber: groups(:bottom_layer_one),
      role_types: [Group::BottomLayer::Member])
    Fabricate(Group::BottomLayer::Member.name, group: groups(:bottom_layer_one), person: top_leader)
    top_leader.update!(address: nil, zip_code: nil, town: "Supertown")
  end

  it "updates success count" do
    subject.run
    expect(message.reload.success_count).to eq 1
  end

  it "returns a result" do
    expect(subject.run.finished?).to be_truthy
  end

  it "creates recipient entries with address" do
    subject.run

    # does not include top leader because no address present
    expect(message.message_recipients).to_not include(top_leader)

    recipient = recipient_entries.first
    expect(recipient.message).to eq message
    expect(recipient.person).to eq bottom_member
    expect(recipient.address).to eq "Bottom Member\nGreatstreet 345\n3456 Greattown"
  end

  it "does not duplicate entries if run is called a second time" do
    2.times { subject.run }

    expect(recipient_entries.count).to eq(1)
  end

  context "company address" do
    it "shows company name first" do
      bottom_member.update(company: true, company_name: "Hitobito AG")

      subject.run

      recipient = recipient_entries.first

      expect(recipient.message).to eq message
      expect(recipient.person).to eq bottom_member
      expect(recipient.address).to eq "Hitobito AG\nBottom Member\nGreatstreet 345\n3456 Greattown"
    end
  end

  context "household addresses" do
    let(:housemate1) do
      Fabricate(:person_with_address, first_name: "Anton", last_name: "Abraham",
        country: not_default_country)
    end
    let(:housemate2) do
      Fabricate(:person_with_address, first_name: "Zora", last_name: "Zaugg",
        country: not_default_country)
    end
    let(:other_housemate) do
      Fabricate(:person_with_address, first_name: "Altra", last_name: "Mates",
        country: not_default_country)
    end

    before do
      Fabricate(Group::BottomLayer::Member.name, group: groups(:bottom_layer_one),
        person: housemate1)
      Fabricate(Group::BottomLayer::Member.name, group: groups(:bottom_layer_one),
        person: housemate2)
    end

    before do
      create_household(housemate1, housemate2)

      # other housemate is not part of member list, so only bottom member should be included without household address
      create_household(people(:bottom_member), other_housemate)
      housemate2.reload
      other_housemate.reload

      top_leader.update!(street: "Fantasia", housenumber: "42", zip_code: "4242", town: "Melmac")
    end

    it "does not concern household addresses" do
      subject.run

      expect(recipient_entries.count).to eq(4)
      housemate1_address =
        "#{housemate1.full_name}\n" \
        "#{housemate1.address}\n" \
        "#{housemate1.zip_code} #{housemate1.town}\n"

      expect(recipient_entry(housemate1).address).to eq(housemate1_address)

      housemate2_address =
        "#{housemate2.full_name}\n" \
        "#{housemate2.address}\n" \
        "#{housemate2.zip_code} #{housemate2.town}\n"

      expect(recipient_entry(housemate2.reload).address).to eq(housemate2_address)

      bottom_member_address =
        "#{bottom_member.full_name}\n" \
        "#{bottom_member.address}\n" \
        "#{bottom_member.zip_code} #{bottom_member.town}"

      expect(recipient_entry(bottom_member).address).to eq(bottom_member_address)

      top_leader_address =
        "#{top_leader.full_name}\n" \
        "#{top_leader.address}\n" \
        "#{top_leader.zip_code} #{top_leader.town}\n"
      expect(recipient_entry(top_leader).address).to eq(top_leader_address)
    end

    it "creates recipient entries with household addresses" do
      message.update!(send_to_households: true)

      subject.run

      expect(recipient_entries.count).to eq(4)
      household_address =
        "#{housemate1.full_name}, #{housemate2.full_name}\n" \
        "#{housemate1.address}\n" \
        "#{housemate1.zip_code} #{housemate1.town}\n"

      expect(recipient_entry(housemate1).address).to eq(household_address)
      expect(recipient_entry(housemate2).address).to eq(household_address)

      bottom_member_address =
        "#{bottom_member.full_name}\n" \
        "#{bottom_member.address}\n" \
        "#{bottom_member.zip_code} #{bottom_member.town}"
      expect(recipient_entry(bottom_member).address).to eq(bottom_member_address)

      top_leader_address =
        "#{top_leader.full_name}\n" \
        "#{top_leader.address}\n" \
        "#{top_leader.zip_code} #{top_leader.town}\n"
      expect(recipient_entry(top_leader).address).to eq(top_leader_address)
    end

    it "creates recipient entries with pre-calculated salutations" do
      message.update!(send_to_households: true)

      subject.run

      expect(recipient_entries.count).to eq(4)

      expect(recipient_entry(housemate1).salutation).to eq("Hallo Anton, hallo Zora")
      expect(recipient_entry(housemate2).salutation).to eq("Hallo Anton, hallo Zora")
      expect(recipient_entry(bottom_member).salutation).to eq("Hallo Bottom")
      expect(recipient_entry(top_leader).salutation).to eq("Hallo Top")
    end

    it "counts households instead of individual people" do
      message.update!(send_to_households: true)

      subject.run

      expect(message.reload.success_count).to eq(3)
    end

    it "adds all names from household address to address box and sorts them alphabetically" do
      message.update!(send_to_households: true)
      housemate3 = Fabricate(:person_with_address, first_name: "Mark", last_name: "Hols",
        country: not_default_country)
      housemate4 = Fabricate(:person_with_address, first_name: "Jana", last_name: "Nicks",
        country: not_default_country)
      housemate5 = Fabricate(:person_with_address, first_name: "Olivia", last_name: "Berms",
        country: not_default_country)
      Fabricate(Group::BottomLayer::Member.name, group: groups(:bottom_layer_one),
        person: housemate3)
      Fabricate(Group::BottomLayer::Member.name, group: groups(:bottom_layer_one),
        person: housemate4)
      Fabricate(Group::BottomLayer::Member.name, group: groups(:bottom_layer_one),
        person: housemate5)

      housemate1.household.destroy
      create_household(housemate1.reload, housemate2.reload, housemate3, housemate4, housemate5)

      subject.run
      address = recipient_entry(housemate2).address.split("\n")
      expect(address).to include("Anton Abraham, Olivia Berms, Mark Hols, Jana Nicks, Zora Zaugg")
    end
  end

  context "large batches" do
    let(:group) { groups(:bottom_layer_one) }
    let(:batch_size) { 3 }

    let(:household_size) { 2 }
    let(:households_count) { ((batch_size * household_size) * 2) + 1 }
    let(:individuals_count) { (batch_size * 2) + 1 }
    let(:mailing_list) { mailing_lists(:leaders) }

    before do
      stub_const("People::HouseholdList::BATCH_SIZE", batch_size)
      Subscription.create!(
        mailing_list: mailing_lists(:leaders),
        subscriber: groups(:bottom_layer_one),
        role_types: [Group::BottomLayer::Member]
      )
      message.update!(send_to_households: true)
      fabricate_valid_households(households_count, household_size)

      individuals_count.times do
        person = Fabricate(:person_with_address, country: not_default_country)
        Fabricate(Group::BottomLayer::Member.name, group: group, person: person)
      end
    end

    it "successfully exports labels with grouped households" do
      # count group members
      amount_of_members = Person.all.count do |person|
        person.roles&.first&.type == Group::BottomLayer::Member.name ||
          person.roles&.to_a&.at(1)&.type == Group::BottomLayer::Member.name ||
          person.roles&.to_a&.at(2)&.type == Group::BottomLayer::Member.name
      end

      expect(amount_of_members).to eq((households_count * household_size) + individuals_count + 2)

      expect { subject.run }.not_to raise_error

      amount_of_expected_mailings = recipient_entries.collect do |recipient|
        recipient.person.household.household_key || recipient.person.id
      end.uniq.count
      expect(amount_of_expected_mailings).to eq(households_count + individuals_count + 1)

      recipient_count = MailingLists::RecipientCounter.new(message.mailing_list, message.class.name, true)
      expect(recipient_count.valid).to eq(households_count + individuals_count + 1)
      expect(message.reload.success_count).to eq(households_count + individuals_count + 1)
      expect(subject.run.finished?).to be_truthy
    end
  end

  private

  def recipient_entry(person)
    recipient_entries.find { |e| e.person_id == person.id }
  end

  def fabricate_recipients(fabricator, num = 1)
    Fabricate.times(num, fabricator, country: not_default_country).tap do |people|
      people.each do |person|
        Fabricate.build(Group::BottomLayer::Member.name, group: groups(:bottom_layer_one),
          person: person).save(validate: false)
      end
    end
  end

  def create_household_new(people)
    household = Household.new(people.first)
    people.each { |member| household.add(member) }
    household.save
    household.reload
  end

  def fabricate_valid_households(num = 1, num_housemates = 2)
    people = fabricate_recipients(:person_with_address, num * num_housemates)
    households = people.each_slice(num_housemates).to_a
    households.each { |housemates| create_household_new(housemates) }
  end
end
