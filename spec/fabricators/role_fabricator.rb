#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

# == Schema Information
#
# Table name: roles
#
#  id          :integer          not null, primary key
#  archived_at :datetime
#  convert_on  :date
#  convert_to  :string
#  delete_on   :date
#  deleted_at  :datetime
#  label       :string
#  terminated  :boolean          default(FALSE), not null
#  type        :string           not null
#  created_at  :datetime
#  updated_at  :datetime
#  group_id    :integer          not null
#  person_id   :integer          not null
#
# Indexes
#
#  index_roles_on_person_id_and_group_id  (person_id,group_id)
#  index_roles_on_type                    (type)
#

Fabricator(:role) do
  person
end

Role.all_types.collect { |r| r.name.to_sym }.each do |t|
  Fabricator(t, from: :role, class_name: t)
end
Fabricator(:future_role, from: :role, class_name: FutureRole) do
  convert_on { Time.zone.tomorrow }
end
