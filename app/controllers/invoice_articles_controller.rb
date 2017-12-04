# encoding: utf-8

#  Copyright (c) 2017, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class InvoiceArticlesController < CrudController

  respond_to :json, only: [:show]

  self.nesting = Group

  self.permitted_attrs = %i[
    number name description category unit_cost vat_rate cost_center account
  ]

  private

  def authorize_class
    authorize!(:index_invoices, parent)
  end

end
