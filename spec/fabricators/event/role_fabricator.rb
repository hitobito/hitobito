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

Fabricator(:event_role, class_name: "Event::Role") do
  participation { Fabricate(:event_participation) }
end

types = Event.role_types + Event::Course.role_types
types.uniq.collect { |t| t.name.to_sym }.each do |t|
  Fabricator(t, from: :event_role, class_name: t)
end
