# frozen_string_literal: true
#
#  Copyright (c) 2018, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class Invoice::PaymentProcessor
  attr_reader :xml

  ESR_FIELD = 'AcctSvcrRef'.freeze

  def initialize(xml)
    @xml = xml
    @data = parse(xml)
  end

  def message_id
    fetch('GrpHdr', 'MsgId')
  end

  def from
    value = fetch_date('FrDtTm')
    to_datetime(value).to_date if value
  end

  def to
    value = fetch_date('ToDtTm')
    to_datetime(value).to_date if value
  end

  def process
    Payment.transaction do
      valid_payments.all?(&:save) || (raise ActiveRecord::Rollback)
      invoice_lists.each(&:update_paid)
      valid_payments.count
    end
  end

  def valid_payments
    @valid_payments ||= payments_with_invoice.select(&:valid?)
  end

  def payments_with_invoice
    @payments_with_invoice ||= payments.select(&:invoice)
  end

  def payments_without_invoice
    payments - payments_with_invoice
  end

  def alert
    translate(:invalid, payments.reject(&:valid?).count)
  end

  def notice
    translate(:valid, payments.count(&:valid?))
  end

  def payments
    @payments ||= credit_statements.collect do |s|
      Payment.new(amount: fetch('Amt', s),
                  esr_number: reference(s),
                  received_at: to_datetime(fetch('RltdDts', 'AccptncDtTm', s)),
                  invoice: invoices[reference(s)],
                  transaction_identifier: fetch('Refs', 'Prtry', 'Ref', s),
                  reference: fetch('Refs', 'AcctSvcrRef', s))
    end
  end

  def invoice_lists
    InvoiceList.where(id: invoices.values.collect(&:invoice_list_id))
  end

  def invoices
    @invoices ||= Invoice
                  .includes(:group, :recipient)
                  .where(reference: references)
                  .index_by(&:reference)
  end

  def references
    credit_statements.collect { |s| reference(s) }
  end

  def credit_statements
    transaction_details
      .select  { |s| fetch('CdtDbtInd', s) == 'CRDT' }
      .reject  { |s| fetch('RmtInf', s)['AddtlRmtInf'] =~ /REJECT/i }
  end

  def transaction_details
    Array.wrap(fetch('Ntfctn', 'Ntry'))
         .collect { |s| fetch('NtryDtls', 'TxDtls', s) }
         .flatten
  end

  def translate(state, count)
    I18n.t("payment_processes.payments.#{state}", count: count) if count > 0
  end

  def parse(xml)
    fetch('Document', 'BkToCstmrDbtCdtNtfctn', Hash.from_xml(xml))
  end

  def fetch(*keys)
    hash = keys.extract_options!.presence || @data
    keys.inject(hash) { |h, key| h.fetch(key) }
  end

  def reference(transaction)
    fetch('RmtInf', 'Strd', 'CdtrRefInf', 'Ref', transaction)
  rescue KeyError
    ''
  end

  def to_datetime(string)
    Time.zone.parse(string)
  end

  def fetch_date(key)
    fetch('Ntfctn').fetch('FrToDt', {})[key]
  end
end
