#  Copyright (c) 2017-2026, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class InvoiceArticlesController < SimpleCrudController
  include VatInclusivePrices

  respond_to :json, only: [:show]

  self.nesting = Group

  self.permitted_attrs =
    [:number, :name, :description, :category, :unit_cost, :vat_rate, :cost_center, :account]

  self.sort_mappings = {
    name: "invoice_article_translations.name",
    description: "invoice_article_translations.description"
  }

  def show
    render json: entry.as_json.merge("unit_cost" => helpers.displayed_unit_cost(entry))
  end

  private

  def group = parent

  def permitted_params
    super.tap { |permitted| convert_unit_cost_to_net(permitted) }
  end

  def authorize_class
    authorize!(:index_issued_invoices, parent)
  end
end
