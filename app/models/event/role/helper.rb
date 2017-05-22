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
#  type             :string           not null
#  participation_id :integer          not null
#  label            :string
#

# Kueche
class Event::Role::Helper < Event::Role

  self.permissions = [:participations_read]

  self.kind = :helper

end
