# frozen_string_literal: true

#  Copyright (c) 2023, Pfadibewegung Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require 'spec_helper'

describe People::Destroyer do
  let(:group) { groups(:bottom_layer_one) }
  let!(:person) { Fabricate(Group::BottomLayer::Member.sti_name.to_sym, group: group).person }
  let(:bottom_member) { people(:bottom_member) }
  let(:top_leader) { people(:top_leader) }

  subject { People::Destroyer.new(person) }

  it 'destroys person' do
    expect do
      subject.run
    end.to change { Person.count }.by(-1)

    expect(Person.exists?(person.id)).to eq(false)
  end

  it 'destroys attached family member if there is only one' do
    leftover_member1 = FamilyMember.create!(person: person, other: bottom_member, kind: :sibling)
    leftover_member2 = FamilyMember.create!(person: top_leader, other: person, kind: :sibling)

    person.reload

    expect do
      subject.run
    end.to change { Person.count }.by(-1)
       .and change { FamilyMember.count }.by(-4)

    expect(FamilyMember.exists?(leftover_member1.id)).to eq(false)
    expect(FamilyMember.exists?(leftover_member2.id)).to eq(false)
  end

  it 'does not destroy attached family members if there is more than one' do
    non_leftover_member1 = FamilyMember.create!(person: person, other: bottom_member, kind: :sibling)
    non_leftover_member2 = FamilyMember.create!(person: top_leader, other: bottom_member, kind: :sibling)

    person.reload

    expect do
      subject.run
    end.to change { Person.count }.by(-1)
       .and change { FamilyMember.count }.by(-4)

    expect(FamilyMember.count).to eq(2)
    expect(FamilyMember.exists?(non_leftover_member1.id)).to eq(false)
    expect(FamilyMember.exists?(non_leftover_member2.id)).to eq(true)
  end

  it 'clears attached household if there is only one other person' do
    person.household_people_ids = [bottom_member.id]
    Person::Household.new(person, Ability.new(top_leader), bottom_member, person).persist!

    person.reload
    bottom_member.reload

    expect(person.household_key).to be_present
    expect(bottom_member.household_key).to eq(person.household_key)

    expect do
      subject.run
    end.to change { Person.count }.by(-1)

    bottom_member.reload

    expect(bottom_member.household_key).to be_nil
  end

  it 'does not clear attached household if there is more than one person' do
    person.household_people_ids = [bottom_member.id, top_leader.id]
    Person::Household.new(person, Ability.new(top_leader), bottom_member, person).persist!
    Person::Household.new(bottom_member, Ability.new(top_leader), top_leader, bottom_member).persist!

    person.reload
    bottom_member.reload
    top_leader.reload

    expect(person.household_key).to be_present
    expect(bottom_member.household_key).to eq(person.household_key)
    expect(top_leader.household_key).to eq(person.household_key)

    expect do
      subject.run
    end.to change { Person.count }.by(-1)

    expect(bottom_member.household_key).to_not be_nil
    expect(top_leader.household_key).to_not be_nil
    expect(bottom_member.household_key).to eq(top_leader.household_key)
  end

  it 'nullifies invoices with person as recipient' do
    invoice = Fabricate(:invoice, group: group, recipient: person)
    person_address = Person::Address.new(person).for_invoice
    person_email = person.email

    expect(invoice.recipient).to eq(person)
    expect(invoice.recipient_address).to eq(person_address)
    expect(invoice.recipient_email).to eq(person_email)

    expect do
      subject.run
    end.to change { Person.count }.by(-1)
       .and change { Invoice.count }.by(0)

    invoice.reload

    expect(invoice.recipient).to be_nil
    expect(invoice.recipient_address).to eq(person_address)
    expect(invoice.recipient_email).to eq(person_email)
  end

  it 'nullifies invoices with person as recipient' do
    invoice = Fabricate(:invoice, group: group, creator: person, recipient: bottom_member)

    expect(invoice.creator).to eq(person)

    expect do
      subject.run
    end.to change { Person.count }.by(-1)
       .and change { Invoice.count }.by(0)

    invoice.reload

    expect(invoice.creator).to be_nil
  end
end
