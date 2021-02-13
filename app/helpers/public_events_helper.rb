# encoding: utf-8

#  Copyright (c) 2012-2015, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module PublicEventsHelper
  def button_action_public_event_apply(event, group)
    if event.application_possible?
      action_button(I18n.t("event_decorator.apply"),
        register_group_event_path(group, event),
        "edit")
    end
  end
end
