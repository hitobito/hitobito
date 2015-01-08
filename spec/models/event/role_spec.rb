# encoding: utf-8
# == Schema Information
#
# Table name: event_roles
#
#  id               :integer          not null, primary key
#  type             :string(255)      not null
#  participation_id :integer          not null
#  label            :string(255)
#

#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.
require 'spec_helper'

describe Event::Role do

  [Event, Event::Course].each do |event_type|
    event_type.role_types.each do |part|
      context part do
        it 'must have valid permissions' do
          # although it looks like, this example is about participation.permissions and not about Participation::Permissions
          Event::Role::Permissions.should include(*part.permissions)
        end
      end
    end
  end

  describe 'destroying roles' do
    before do
      @role = Event::Role::Participant.new
      @role.participation = participation
      @role.save!
    end

    let(:event) { events(:top_event) }
    let(:role)  { @role.reload }
    let(:participation) { Fabricate(:event_participation, event: event, active: true) }

    it 'decrements event#(representative_)participant_count' do
      event.reload
      participant_count = event.participant_count
      applicant_count = event.applicant_count

      role.destroy

      event.reload
      event.participant_count.should eq participant_count - 1
      event.applicant_count.should eq applicant_count - 1
    end

    it 'decrements event#participant_count if participations has other non participant roles' do
      treasurer = Event::Role::Treasurer.new
      treasurer.participation = Fabricate(:event_participation, event: event, active: true)
      treasurer.save!

      event.reload
      participant_count = event.participant_count
      applicant_count = event.applicant_count

      role.destroy

      event.reload
      event.participant_count.should eq participant_count - 1
      event.applicant_count.should eq applicant_count - 1
    end

  end
end
