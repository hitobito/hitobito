#  Copyright (c) 2014, CEVI ZH SH GL. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

if group
  json.id   group.id
  json.href group_url(group, format: :json)
  json.name group.to_s
  json.type group.class.label
else
  json.null!
end