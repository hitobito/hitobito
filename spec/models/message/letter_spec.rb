# frozen_string_literal: true

#  Copyright (c) 2012-2021, CVP Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require 'spec_helper'

describe Message::Letter do

  let(:list) { mailing_lists(:leaders) }
  let(:entry) { Fabricate(:letter, mailing_list: list) }

  describe 'recipient count' do
    before do
      Subscription.create!(mailing_list: list, subscriber: groups(:top_group), role_types: [Group::TopGroup::Leader])
      # people with address
      42.times do
        person = Fabricate(:person_with_address)
        add_to_group(person)
        # make sure people are only counted once
        Group::TopLayer::TopAdmin.create!(group: groups(:top_layer), person: person)
      end

      # person without address
      add_to_group(Fabricate(:person))
    end

    it 'calculates number of people with complete address' do
      expect(entry.total_recipient_count).to eq(44)
      expect(entry.valid_recipient_count).to eq(42)
    end
  end

  private

  def add_to_group(person)
    Group::TopGroup::Leader.create!(group: groups(:top_group), person: person)
  end

end
