# frozen_string_literal: true

#  Copyright (c) 2023, Schweizer Wanderwege. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module Sheet
  class Invoices::ByArticle < Sheet::Invoice
    def title
      case view.params[:type]&.to_sym
      when :deficit
        I18n.t("invoices.evaluations.show.deficit")
      when :excess
        I18n.t("invoices.evaluations.show.excess")
      when :by_article
        I18n.t("invoices/by_article.index.title", name: view.params[:name])
      end
    end
  end
end
