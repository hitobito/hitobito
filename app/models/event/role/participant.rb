# encoding: utf-8

#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

# == Schema Information
#
# Table name: event_roles
#
#  id               :integer          not null, primary key
#  type             :string(255)      not null
#  participation_id :integer          not null
#  label            :string(255)
#

# Teilnehmer
class Event::Role::Participant < Event::Role

  self.permissions = [:contact_data]

  self.kind = :participant

  after_create :update_count
  after_destroy :update_count


  private

  # if participation was removed, we must retrieve event
  # participation we still have in memory
  def update_count
    event ||= participation.event
    if event
      event.refresh_participant_count!
      event.refresh_representative_participant_count!
    end
  end

end
