#  Copyright (c) 2026, BdP and DPSG. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class InvoiceRuns::InvoicesController < InvoicesController
  def index
    recipient_info
    super
  end

  private

  def recipient_info
    return unless invoice_run.invalid_recipient_ids.any?
    flash.now[:warning] = invalid_recipient_info
  end

  def invalid_recipient_info
    t(".invalid_recipients", count: invoice_run.invalid_recipient_ids.count,
      recipients: invalid_recipients)
  end

  def invalid_recipients
    invoice_run.recipients(current_user)
      .where(id: invoice_run.invalid_recipient_ids).map(&:to_s).join(", ")
  end

  def invoice_run
    parent
  end
end
