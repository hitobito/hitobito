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
    @payments ||= debit_statements.collect do |s|
      Payment.new(amount: fetch('Amt', s),
                  esr_number: esr_number(s),
                  received_at: to_datetime(fetch('RltdDts', 'AccptncDtTm', s)),
                  invoice: invoices[esr_number(s)],
                  reference: fetch('Refs', 'AcctSvcrRef', s))
    end
  end

  def invoices
    @invoices ||= Invoice
                  .includes(:group, :recipient)
                  .where(esr_number: esr_numbers)
                  .index_by(&:esr_number)
  end

  def esr_numbers
    debit_statements.collect { |s| esr_number(s) }
  end

  def debit_statements
    transaction_details
      .select  { |s| fetch('CdtDbtInd', s) == 'DBIT' }
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

  def esr_number(transaction)
    to_esr(fetch('RmtInf', 'Strd', 'CdtrRefInf', 'Ref', transaction))
  end

  def to_esr(string)
    string[2..-1].scan(/\d{5}/).prepend(string[0..1]).join(' ')
  end

  def to_datetime(string)
    Time.zone.parse(string)
  end

  def fetch_date(key)
    fetch('Ntfctn').fetch('FrToDt', {})[key]
  end
end
