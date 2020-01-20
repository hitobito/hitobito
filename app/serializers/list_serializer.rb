# encoding: utf-8

#  Copyright (c) 2014, CEVI Regionalverband ZH-SH-GL. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class ListSerializer < ApplicationSerializer
  schema do
    real_item = item.try(:decorated?) ? item.send(:object) : item

    t = real_item.klass.model_name.plural
    type t
    collection t, item, context[:serializer]
  end
end
