#  Copyright (c) 2014, CEVI Regionalverband ZH-SH-GL. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class GroupLinkSerializer < ApplicationSerializer
  schema do
    json_api_properties

    property :name, item.to_s
    property :group_type, item.class.label
  end
end
