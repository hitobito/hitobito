# frozen_string_literal: true

#  Copyright (c) 2012-2021, CVP Schweiz. This file is part of
#  hitobito_cvp and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_cvp.

module Messages
  class LetterWithInvoiceDispatch < LetterDispatch

    def initialize(*args)
      super
      @invoice_list = @message.invoice_list
      @invoice_list.invoice = @message.invoice
    end

    def run
      super
      @message.update(invoice_list_id: @invoice_list.id)
      batch_create
      Invoice::BatchUpdate.new(@invoice_list.reload.invoices, @message.sender).call
    end

    def batch_create
      batch_create = Invoice::BatchCreate.new(@invoice_list, @people)
      batch_create.call

      update(success_count: batch_create.results.count(true),
             failed_count: batch_create.results.count(false))
    end
  end
end
