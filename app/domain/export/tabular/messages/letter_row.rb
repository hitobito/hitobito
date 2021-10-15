# frozen_string_literal: true

#  Copyright (c) 2021, Die Mitte Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module Export::Tabular::Messages
  class LetterRow < Export::Tabular::People::HouseholdRow

    def household
      [entry]
    end

    def entry
      @entry.person
    end

    def salutation
      @entry&.salutation
    end

    def printed_address
      @entry&.address
    end

  end
end
