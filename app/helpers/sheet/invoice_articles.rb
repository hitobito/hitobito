#  Copyright (c) 2026, Schweizer Wanderwege. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module Sheet
  class InvoiceArticles < Sheet::Invoice
    def title
      ::InvoiceArticle.model_name.human(count: 2)
    end

    def link_url
      view.group_invoice_articles_path(view.parent, returning: true)
    end

    # Needs spacing because parent has no tabs
    def render_parent_title
      content_tag(:div, super, class: "pb-3")
    end

    private

    def find_entry
      nil
    end
  end
end
