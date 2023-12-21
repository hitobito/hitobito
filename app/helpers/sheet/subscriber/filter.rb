# frozen_string_literal: true

#  Copyright (c) 2012-2023, Pfadibewegung Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module Sheet
  module Subscriber
    class Filter < Base
      self.parent_sheet = Sheet::MailingList
    end
  end
end
