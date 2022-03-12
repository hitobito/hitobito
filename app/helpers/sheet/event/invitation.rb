# encoding: utf-8

#  Copyright (c) 2021, CEVI ZH SH GL. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module Sheet
  class Event
    class Invitation < Sheet::Base
      self.parent_sheet = Sheet::Event
    end
  end
end
