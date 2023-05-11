#  frozen_string_literal: true

#  Copyright (c) 2023, Jungwacht Blauring Schweiz. This file is part of
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

Fabricator(:event_invitation, class_name: 'Event::Invitation') do
  participation_type { Event::Role::Participant.name }
  event
  person
end
