# frozen_string_literal: true

#  Copyright (c) 2023, Schweizer Wanderwege. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class InvoiceLists::DestroysController < CrudController
  skip_authorization_check
  skip_authorize_resource

  respond_to :js

  helper_method :deletable?

  def destroy
    authorize!(:destroy, entry)

    raise ActiveRecord::RecordInvalid unless deletable? # is there a better error?

    super
  end

  def show
    @message = entry.message
    non_draft_invoice_present
  end

  def self.model_class
    InvoiceList
  end

  private

  def destroy_return_path(_destroyed, _options = {})
    group_invoice_lists_path(entry.group)
  end

  def deletable?
    !non_draft_invoice_present
  end

  def non_draft_invoice_present
    @non_draft_invoice_present ||= entry.invoices.any? { |i| !(i.draft? || i.cancelled?) }
  end

  def entry
    @entry ||= InvoiceList.find(params[:invoice_list_id])
  end

  def group
    @group ||= Group.find(params[:group_id])
  end
end
