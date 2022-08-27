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

  def self.format_as_esr(string)
    string.reverse.gsub(/(.{5})/, '\1 ').reverse
  end

  def initialize(invoice = nil)
    @invoice = invoice
  end

  def esr_number
    Invoice::PaymentSlip.format_as_esr(number_string_with_check)
  end

  def check_digit(string)
    number = string.each_char.inject(0) do |digit, char|
      current_digit = digit + char.to_i
      ESR9_TABLE[current_digit % 10]
    end
    (10 - number) % 10
  end

  def code_line
    "#{code_line_prefix}>#{number_string_with_check}+ #{code_line_suffix}>"
  end

  def padded_number
    if invoice.participant_number_internal
      [zero_padded(invoice.participant_number_internal, 6), zero_padded(group_id, 7)].join
    else
      zero_padded(group_id, 13)
    end
  end

  private

  def number_string
    [padded_number, zero_padded(index, 13)].join
  end

  def code_line_prefix
    block = ''
    block << BCS[calculate_bc.to_sym]
    block << format('%011.2f', invoice.total).delete('.') if calculate_bc == 'esr' && show_total?
    block << check_digit(block).to_s
  end

  def code_line_suffix
    participant_number_parts.each_with_index.inject('') do |block, (nr, i)|
      block << (i != 1 ? nr : zero_padded(nr, 6))
    end
  end

  def calculate_bc
    invoice.invoice_items.present? ? 'esr' : 'esr_plus'
  end

  def number_string_with_check
    number_string + check_digit(number_string).to_s
  end

  def group_id
    invoice.sequence_number.split('-')[0]
  end

  def index
    invoice.sequence_number.split('-')[1]
  end

  def participant_number_parts
    invoice.participant_number.split('-')
  end

  def zero_padded(string, length)
    format("%0#{length}d", string[0..(length - 1)].to_i)
  end

  def show_total?
    !@invoice.hide_total?
  end

end
