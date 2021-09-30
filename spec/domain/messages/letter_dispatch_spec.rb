# frozen_string_literal: true

#  Copyright (c) 2012-2021, CVP Schweiz. This file is part of
#  hitobito_cvp and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require 'spec_helper'

describe Messages::LetterDispatch do
  let(:message)    { messages(:letter) }
  let(:top_leader) { people(:top_leader) }
  let(:bottom_member) { people(:bottom_member) }
  let(:recipient_entries) { message.message_recipients }
  let(:list_members) { Person.where(id: [top_leader.id, bottom_member.id]) }

  subject { described_class.new(message, list_members) }

  it 'updates success count' do
    subject.run
    expect(message.reload.success_count).to eq 1
  end

  it 'creates recipient entries with address' do
    subject.run

    expect(message.message_recipients).to_not include(top_leader)

    recipient = recipient_entries.first
    expect(recipient.message).to eq message
    expect(recipient.person).to eq bottom_member
    expect(recipient.address).to eq "Bottom Member\nGreatstreet 345\n3456 Greattown\nCH"
  end

  context 'household addresses' do

    let(:housemate1) { Fabricate(:person_with_address) }
    let(:housemate2) { Fabricate(:person_with_address) }
    let(:list_members) { Person.where(id: [top_leader, bottom_member, housemate1, housemate2]) }

    before do
      Fabricate(Group::BottomGroup::Member.name.to_sym, group: groups(:bottom_group_one_one), person: housemate1)
      Fabricate(Group::BottomGroup::Member.name.to_sym, group: groups(:bottom_group_one_one), person: housemate2)
      fake_ability = instance_double('aby', cannot?: false)
      Person::Household.new(housemate1, fake_ability, housemate2).assign
    end

    it 'does not concern household addresses' do
      subject.run

      recipient = recipient_entries.first
    end

    it 'creates recipient entries with household addresses' do
      message.update!(send_to_households: true)

      subject.run

      expect(recipient_entries.count).to eq(3)
    end
  end
end
