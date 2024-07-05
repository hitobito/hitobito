#  Copyright (c) 2014, CEVI Regionalverband ZH-SH-GL. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class PersonIdSerializer < ApplicationSerializer
  schema do
    type "people"
    property :id, item.to_s
    property :type, "people"
  end
end
