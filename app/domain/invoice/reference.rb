# frozen_string_literal: true

#  Copyright (c) 2012-2020, CVP Schweiz. This file is part of
#  hitobito_cvp and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_cvp.

class Invoice::Reference

  QR_ID_RANGE = (30_000..31_999).freeze
  SEPARATOR_SUBSTITUTE = 'ZZ'

  def self.create(invoice)
    new(invoice).create
  end

  def initialize(invoice)
    @invoice = invoice
  end

  def create
    if qr_without_qr_iban?
      scor_reference
    else
      @invoice.esr_number.delete(' ')
    end
  end

  def scor_reference
    value = @invoice.sequence_number.tr(Invoice::SEQUENCE_NR_SEPARATOR, SEPARATOR_SUBSTITUTE)
    Invoice::ScorReference.create(value)
  end

  def qr_without_qr_iban?
    @invoice.iban && @invoice.qr? && !QR_ID_RANGE.include?(qr_id)
  end

  def qr_id
    @invoice.iban.delete(' ')[4..8].to_i
  end
end
