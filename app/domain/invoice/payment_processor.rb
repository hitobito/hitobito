# frozen_string_literal: true

#  Copyright (c) 2018-2022, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class Invoice::PaymentProcessor
  attr_reader :xml

  ESR_FIELD = 'AcctSvcrRef'

  def initialize(xml)
    @xml = xml
    @data = parse(xml)
  end

  def process
    Payment.transaction do
      valid_payments.all?(&:save) || (raise ActiveRecord::Rollback)
      invoice_lists.each(&:update_paid)
      valid_payments.count
    end
  end

  def payments
    @payments ||= net_entries.flat_map do |n|
      credit_statements(n).collect do |s|
        init_payment(s, n)
      end
    end
  end

  def alert
    translate(:invalid, invalid_payments.count)
  end

  def notice
    return if valid_payments.empty?

    [
      translate(:valid_with_invoice, valid_payments_with_invoice.count),
      translate(:valid_without_invoice, valid_payments_without_invoice.count)
    ].select(&:present?).compact.join("\n")
  end

  def to
    value = fetch_date('ToDtTm')
    to_datetime(value).to_date if value
  end

  def from
    value = fetch_date('FrDtTm')
    to_datetime(value).to_date if value
  end

  def payments_with_invoice
    @payments_with_invoice ||= payments.select(&:invoice)
  end

  def payments_without_invoice
    payments - payments_with_invoice
  end

  def valid_payments
    @valid_payments ||= payments.select(&:valid?)
  end

  def invalid_payments
    @invalid_payments ||= payments - valid_payments
  end

  def valid_payments_with_invoice
    valid_payments - payments_without_invoice
  end

  def valid_payments_without_invoice
    valid_payments - payments_with_invoice
  end

  private

  def init_payment(statement, net_entry)
    Payment.new(amount: fetch('Amt', statement),
                esr_number: reference(statement),
                received_at: received_at(net_entry, statement),
                invoice: invoice(statement),
                transaction_identifier: transaction_identifier(net_entry, statement),
                reference: esr_reference(statement),
                transaction_xml: statement.to_xml(root: :TxDtls, skip_instruct: true).squish,
                status: :xml_imported,
                payee_attributes: {
                  person_id: invoice(statement)&.recipient_id,
                  person_name: person_name(statement),
                  person_address: person_address(statement)
                })
  end

  def message_id
    fetch('GrpHdr', 'MsgId')
  end

  def person_name(statement)
    fetch('RltdPties', 'Dbtr', 'Nm', statement)
  rescue KeyError
    ''
  end

  def person_address(statement)
    street, house_number, zip, town = ['StrtNm', 'BldgNb', 'PstCd', 'TwnNm'].map do |key|
      begin
        fetch('RltdPties', 'Dbtr', 'PstlAdr', key, statement)
      rescue KeyError
        ''
      end
    end

    "#{street} #{house_number}, #{zip} #{town}"
  end

  def invoice(statement)
    invoices_by_reference[reference(statement)] || invoices_by_esr_number[esr_number(statement)]
  end

  def invoices
    @invoices ||= invoices_by_reference
  end

  def invoice_lists
    InvoiceList.where(id: invoices.values.collect(&:invoice_list_id))
  end

  def invoices_by_reference
    @invoices_by_reference ||= Invoice
                               .includes(:group, :recipient)
                               .where(reference: references)
                               .index_by(&:reference)
  end

  def invoices_by_esr_number
    @invoice_by_esr_number ||= Invoice
      .includes(:group, :recipient)
      .where(esr_number: esr_numbers)
      .index_by(&:esr_number)
  end

  def references
    credit_statements.collect { |s| reference(s) }
  end

  def esr_numbers
    references.map { |r| Invoice::PaymentSlip.format_as_esr(r) }
  end

  def net_entries
    Array.wrap(fetch('Ntfctn', 'Ntry'))
  end

  def credit_statements(net_entry = fetch('Ntfctn', 'Ntry'))
    transaction_details(net_entry)
      .select  { |s| fetch('CdtDbtInd', s) == 'CRDT' }
      .reject  { |s| fetch('RmtInf', s)['AddtlRmtInf'] =~ /REJECT/i }
  end

  def transaction_details(net_entry = fetch('Ntfctn', 'Ntry'))
    Array.wrap(net_entry)
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

  def esr_reference(transaction)
    fetch('Refs', 'AcctSvcrRef', transaction)
  rescue KeyError
    nil
  end

  def received_at(net_entry, transaction)
    datetime = net_entry.dig('ValDt', 'Dt') ||
      transaction.dig('RltdDts', 'AccptncDtTm') ||
      from.to_s ||
      fetch('Ntfctn').fetch('CreDtTm')
    to_datetime(datetime)
  end

  def transaction_identifier(net_entry, transaction)
    [
      esr_reference(transaction),
      reference(transaction),
      transaction.dig('Amt'),
      received_at(net_entry, transaction),
      debitor_iban(transaction)
    ].join
  end

  def debitor_iban(transaction)
    transaction.dig('RltdPties', 'DbtrAcct', 'Id', 'IBAN')
  rescue KeyError
    ''
  end

  def esr_number(transaction)
    Invoice::PaymentSlip.format_as_esr(reference(transaction))
  end

  def to_datetime(string)
    Time.zone.parse(string)
  end

  def fetch_date(key)
    fetch('Ntfctn').fetch('FrToDt', {})[key]
  end
end
