#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module Sheet
  class Event
    class Participation < Base
      self.parent_sheet = Sheet::Event

      tab "global.tabs.info",
        :group_event_participation_path,
        if: :show_details

      tab "global.tabs.log",
        :log_group_event_participation_path,
        if: (lambda do |view, _group, event, participation|
          view.can?(:update, participation)
        end)
    end
  end
end
