# frozen_string_literal: true

#  Copyright (c) 2022, Schweizer Wanderwege. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class Invoices::RecalculateController < ApplicationController

  respond_to :js
  before_action :authorize_action
  helper_method :entry

  def new;end

  private

  def entry
    @entry ||= build_entry
  end

  def build_entry
    invoice = Invoice.new
    if params.dig(:invoice_list, :invoice).present?
      invoice.attributes = params.require(:invoice_list).require(:invoice).permit(InvoicesController.permitted_attrs)
    else
      invoice.attributes = params.require(:invoice).permit(InvoicesController.permitted_attrs)
    end
    invoice.group = group
    invoice
  end

  def group
    @group ||= Group.find(params[:group_id])
  end

  class << self
    def model_class
      @model_class = Invoice
    end
  end

  def authorize_action
    authorize!(:index_invoices, group)
  end
end

