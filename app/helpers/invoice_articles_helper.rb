#  Copyright (c) 2012-2020, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module InvoiceArticlesHelper

  def format_invoice_article_unit_cost(invoice_article)
    currency = invoice_article.group.invoice_config.currency
    number_to_currency(invoice_article.unit_cost, unit: currency)
  end

  def link_invoice_list_by_article(group, from, to, entry)
    link_to(group_invoices_by_article_index_path(
              group_id: group.id,
              from: from,
              to: to,
              name: entry[:name],
              account: entry[:account],
              cost_center: entry[:cost_center]
            )) do
      yield if block_given?
    end
  end
end
