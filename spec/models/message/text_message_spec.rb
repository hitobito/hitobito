# frozen_string_literal: true

#  Copyright (c) 2012-2021, CVP Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require 'spec_helper'

describe Message::TextMessage do

  let(:list) { mailing_lists(:leaders) }
  let(:entry) { Fabricate(:text_message, mailing_list: list) }

  describe 'recipient count' do
    before do
      Subscription.create!(mailing_list: list, subscriber: groups(:top_group), role_types: [Group::TopGroup::Leader])
      # people with Mobil number
      42.times do
        person = Fabricate(:phone_number, label: 'Mobil').contactable
        add_to_group(person)
      end

      # person with no mobile phone number
      person2 = Fabricate(:phone_number, label: 'Fax').contactable
      Fabricate(:phone_number, label: 'Privat', contactable: person2)
      add_to_group(person2)

      # person without any phone numbers
      person3 = Fabricate(:person)
      add_to_group(person3)

      # person with mobile and other phone numbers
      person4 = Fabricate(:phone_number, label: 'Mobil').contactable
      Fabricate(:phone_number, label: 'Privat', contactable: person4)
      add_to_group(person4)
      # make sure people are only counted once
      Group::TopLayer::TopAdmin.create!(group: groups(:top_layer), person: person4)
    end

    it 'calculates number of people with mobile phone number' do
      expect(entry.total_recipient_count).to eq(46)
      expect(entry.valid_recipient_count).to eq(43)
    end
  end

  private

  def add_to_group(person)
    Group::TopGroup::Leader.create!(group: groups(:top_group), person: person)
  end

end
