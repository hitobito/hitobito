# encoding: utf-8

#  Copyright (c) 2017, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class Invoice::EsrNumber

  attr_reader :sequence_number

  ESR9_TABLE = [0, 9, 4, 6, 8, 2, 7, 1, 3, 5].freeze

  def initialize(sequence_number = '')
    @sequence_number = sequence_number
  end

  def generate
    esr_number = sequence_number.split('-').map { |nr| format('%013d', nr.to_i) }.join
    esr_number = "#{esr_number}#{check_digit(esr_number)}"
    esr_number.reverse.gsub(/(.{5})/, '\1 ').reverse
  end

  private

  def check_digit(number)
    digit = 0
    number.split('').each do |char|
      current_digit = digit + char.to_i
      digit = ESR9_TABLE[current_digit % 10]
    end
    (10 - digit) % 10
  end

end
