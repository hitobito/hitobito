# frozen_string_literal: true

#  Copyright (c) 2012-2021, CVP Schweiz. This file is part of
#  hitobito_cvp and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_cvp.

module Messages
  class LetterWithInvoiceDispatch < LetterDispatch
    def initialize(*args)
      super
      @invoice_run = @message.invoice_run
      @invoice_run.invoice = @message.invoice
    end

    def run
      super

      @message.update!(invoice_run_id: @invoice_run.id)
      batch_create # create invoices for all people on the invoice run
      # rubocop:todo Layout/LineLength
      batch_update # update invoices by advancing their state, sending mail and create reminders if needed
      # rubocop:enable Layout/LineLength
      DispatchResult.finished
    end

    def batch_create
      batch_create = Invoice::BatchCreate.new(@invoice_run, @people)
      batch_create.call

      @message.update!(
        success_count: batch_create.results.count(true),
        failed_count: batch_create.results.count(false)
      )
    end

    def batch_update
      Invoice::BatchUpdate.new(@invoice_run.reload.invoices).call
    end

    # disable household addresses for letter with invoice
    def send_to_households?
      false
    end

    private

    def address_for_letter(person, _housemates)
      Person::Address.new(person).for_letter_with_invoice
    end
  end
end
