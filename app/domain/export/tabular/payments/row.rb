# frozen_string_literal: true

#  Copyright (c) 2022, Die Mitte Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module Export::Tabular::Payments
  class Row < Export::Tabular::Row
    def payee_person_name
      entry&.payee&.person_name
    end

    def payee_person_address
      entry&.payee&.person_address
    end
  end
end
