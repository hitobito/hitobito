# encoding: utf-8

#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class Event::RoleDecorator < ApplicationDecorator
  decorates 'event/role'

  def flash_info
    "<i>#{h.h(model)}</i> für <i>#{h.h(participation.person)}</i> in <i>#{h.h(participation.event)}</i>".html_safe
  end
end
