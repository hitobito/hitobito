# encoding: utf-8

#  Copyright (c) 2017, CVJM. This file is part of
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

# Kueche
class Event::Role::Helper < Event::Role

  self.permissions = [:participations_read]

  self.kind = :helper

end
