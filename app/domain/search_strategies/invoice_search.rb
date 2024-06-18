#  Copyright (c) 2012-2024, Hitobito AG. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module SearchStrategies
  class InvoiceSearch < Base
    def search_fulltext
      return no_invoices unless term_present?
      return no_invoices if @user.finance_groups.empty?

      Invoice.search(@term)
    end   

    private

    def no_invoices
      Invoice.none.page(1)
    end
  end
end