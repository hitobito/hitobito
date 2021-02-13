# frozen_string_literal: true

#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.
# == Schema Information
#
# Table name: event_roles
#
#  id               :integer          not null, primary key
#  label            :string(255)
#  type             :string(255)      not null
#  participation_id :integer          not null
#
# Indexes
#
#  index_event_roles_on_participation_id  (participation_id)
#  index_event_roles_on_type              (type)
#

# Kursteilnehmer
module Event::Course::Role
  class Participant < ::Event::Role::Participant
    class << self
      # A course participant is restricted because it may not just be added by
      # a course leader, but only over the special application market view.
      def restricted?
        true
      end
    end
  end
end
