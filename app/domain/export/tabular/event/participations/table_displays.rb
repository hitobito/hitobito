# frozen_string_literal: true

#  Copyright (c) 2022, Schweizer Blasmusikverband. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module Export::Tabular::Event::Participations
  class TableDisplays < Export::Tabular::People::TableDisplays

    self.model_class = ::Person
    self.row_class = TableDisplayRow

    def public_account_labels(accounts, klass)
      account_labels(list.map(&:person).map(&accounts).flatten.select(&:public?), klass)
    end

  end
end
