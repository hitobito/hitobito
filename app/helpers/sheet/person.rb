# encoding: utf-8

#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module Sheet
  class Person < Base

    self.parent_sheet = Sheet::Group
    self.has_tabs = true

    def link_url
      view.group_person_path(parent_sheet.entry.id, entry.id)
    end

  end
end
