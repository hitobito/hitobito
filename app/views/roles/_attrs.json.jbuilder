#  Copyright (c) 2014, CEVI ZH SH GL. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

json.extract!(role, :id)
json.type role.class.label

json.extract!(role, :label,
                    :created_at,
                    :updated_at,
                    :deleted_at)

json.group do
  json.partial! 'groups/link', group: role.group
end

json.layer do
  json.partial! 'groups/link', group: role.group.layer_group
end
