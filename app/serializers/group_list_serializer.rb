#  Copyright (c) 2020, Pfadibewegung Schweiz. This file is part of
#  hitobito_pbs and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_pbs.

class GroupListSerializer < ApplicationSerializer
  schema do
    type "group"
    property :id, item.id
    property :parent_id, item.parent_id
    property :type, item.type
  end
end
