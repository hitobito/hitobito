# encoding: utf-8

#  Copyright (c) 2017, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class Invoice::PaymentSlip

  # Defined at http://www.pruefziffernberechnung.de/E/Einzahlungsschein-CH.shtml
  ESR9_TABLE = [0, 9, 4, 6, 8, 2, 7, 1, 3, 5].freeze
  BCS = { esr: '01', esr_plus: '04' }.freeze

  attr_reader :invoice

  def initialize(invoice = nil)
    @invoice = invoice
  end

  def esr_number
    esr_number = invoice.sequence_number.split('-').map { |nr| format('%013d', nr.to_i) }.join
    esr_number = "#{esr_number}#{check_digit(esr_number)}"
    esr_number.reverse.gsub(/(.{5})/, '\1 ').reverse
  end

  def code_line
    code_line = ''
    code_line << first_code_line_block
    code_line << "#{invoice.esr_number.delete(' ')}+ "
    code_line << last_code_line_block
  end

  def check_digit(number)
    digit = 0
    number.each_char.each do |char|
      current_digit = digit + char.to_i
      digit = ESR9_TABLE[current_digit % 10]
    end
    (10 - digit) % 10
  end

  private

  def first_code_line_block
    block = ''
    block << BCS[calculate_bc.to_sym]
    block << format('%010d', invoice.total.to_s.delete('.').to_i) if calculate_bc == 'esr'
    block << "#{check_digit(block)}>"
  end

  def last_code_line_block
    block = ''
    invoice.account_number.split('-').each_with_index do |nr, i|
      next block << nr if i != 1
      block << format('%06d', nr.to_i)
    end
    "#{block}>"
  end

  def calculate_bc
    invoice.invoice_items.present? ? 'esr' : 'esr_plus'
  end

end
