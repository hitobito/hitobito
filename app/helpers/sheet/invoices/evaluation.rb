# frozen_string_literal: true

#  Copyright (c) 2022, Schweizer Wanderwege. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module Sheet
  class Invoices::Evaluation < Sheet::Invoice

    def title
      I18n.t('invoices.evaluations.show.title')
    end

  end
end
