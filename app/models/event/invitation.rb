# frozen_string_literal: true

#  Copyright (c) 2021, CEVI ZH SH GL. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

# == Schema Information
#
# Table name: event_invitations
#
#  id                     :integer          not null, primary key
#  participation_type     :string           not null
#  declined_at            :datetime
#  event_id               :integer          not null
#  person_id              :integer          not null
#  created_at             :datetime
#  updated_at             :datetime
#

class Event::Invitation < ActiveRecord::Base

  self.demodulized_route_keys = true

  belongs_to :event
  belongs_to :person

  def status
    if related_participation.present?
      :accepted
    elsif declined_at.present?
      :declined
    else
      :open
    end
  end

  def open?
    status == :open
  end

  def related_participation
    Event::Participation.find_by(person_id: self.person_id,
                                 event_id: self.event_id)
  end
end
