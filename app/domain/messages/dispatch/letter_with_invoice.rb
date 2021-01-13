# frozen_string_literal: true

#  Copyright (c) 2012-2021, CVP Schweiz. This file is part of
#  hitobito_cvp and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_cvp.

module Messages::Dispatch
  class LetterWithInvoice
    delegate :update, :success_count, to: '@dispatch'

    def initialize(dispatch, people, sender)
      @dispatch = dispatch
      @people = people
      @sender = sender
      @now = Time.current
    end

    def run
      invoice_list.save!
      ## TODO
      Invoice::BatchCreate.create(invoice_list, message.invoice.attributes)
      Invoice::BatchUpdate.new(invoice_list.invoices, sender).call
    end

  end
end
