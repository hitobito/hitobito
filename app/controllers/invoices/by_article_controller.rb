# frozen_string_literal: true

#  Copyright (c) 2023, Schweizer Wanderwege. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class Invoices::ByArticleController < ListController
  self.nesting = Group

  def self.model_class
    Invoice
  end

  helper_method :from_date, :to_date

  def list_entries
    invoice_ids = Payments::Collection
      .new
      .in_layer(group.id)
      .from(from_date)
      .to(to_date)
      .having_invoice_item(params[:name], params[:account], params[:cost_center])
      .payments
      .pluck(:invoice_id)

    Invoice.where(id: invoice_ids).page(params[:page]).per(50)
  end

  private

  def from_date
    Date.parse(params[:from]) if params[:from].present?
  end

  def to_date
    Date.parse(params[:to]) if params[:from].present?
  end

  def group
    @group ||= Group.find(params[:group_id])
  end

  def authorize_class
    authorize!(:index_invoices, group)
  end
end
