# frozen_string_literal: true

#  Copyright (c) 2017 - 2018, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class MailingList::Filter::Chain < Filter::Chain

  TYPES = [ # rubocop:disable Style/MutableConstant these are meant to be extended in wagons
    # MailingList::Filter::Attributes,
  ]

end
