#  Copyright (c) 2012-2020, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module InvoiceArticlesHelper

  def format_invoice_article_unit_cost(invoice_article)
    currency = invoice_article.group.invoice_config.currency
    number_to_currency(invoice_article.unit_cost, unit: currency)
  end

end
