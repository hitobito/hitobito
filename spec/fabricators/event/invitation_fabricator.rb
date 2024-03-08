#  frozen_string_literal: true

#  Copyright (c) 2023, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

# == Schema Information
#
# Table name: event_invitations
#
#  id                 :bigint           not null, primary key
#  declined_at        :datetime
#  participation_type :string(255)      not null
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#  event_id           :bigint           not null
#  person_id          :bigint           not null
#
# Indexes
#
#  index_event_invitations_on_event_id                (event_id)
#  index_event_invitations_on_event_id_and_person_id  (event_id,person_id) UNIQUE
#  index_event_invitations_on_person_id               (person_id)
#

Fabricator(:event_invitation, class_name: 'Event::Invitation') do
  participation_type { Event::Role::Participant.name }
  event
  person
end
