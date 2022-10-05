# frozen_string_literal: true

#  Copyright (c) 2022, Schweizer Wanderwege. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

# Handles a top-level invoice route (/invoice/:id)
class Invoices::TopController < ApplicationController

  before_action :authorize_action

  def show
    redirect_to_group_invoice
  end

  private

  def entry
    @invoice ||= Invoice.find(params[:id])
  end

  def redirect_to_group_invoice
    flash.keep if html_request?
    redirect_to group_invoice_path(entry.group, entry, format: request.format.to_sym)
  end

  def authorize_action
    authorize!(:show, entry)
  end

end
