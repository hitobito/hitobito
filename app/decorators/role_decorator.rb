# encoding: utf-8

#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class RoleDecorator < ApplicationDecorator
  decorates :role

  def used_attributes(*attributes)
    attributes.select { |name| model.class.attr_used?(name) }
  end

  def flash_info
    "<i>#{h.h(model)}</i> für <i>#{h.h(person)}</i> in <i>#{h.h(group)}</i>".html_safe
  end

end
