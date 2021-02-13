# frozen_string_literal: true

#  Copyright (c) 2012-2020, CVP Schweiz. This file is part of
#  hitobito_cvp and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_cvp.

class Invoice::ScorReference
  # Simple Creditor Reference ISO 11649 generator
  # https://www.mobilefish.com/services/creditor_reference/creditor_reference.php

  PREFIX = "RF"
  REGEXP = /^[\d[a-z]]+$/i.freeze

  def self.create(reference)
    new(reference).create
  end

  def initialize(reference)
    @reference = reference.to_s
    @chars = reference.split("")
  end

  def create
    raise "Invalid size" unless right_size?
    raise "Invalid characters" unless right_chars?

    mapped = @chars.collect { |char| map(char).to_s }.join
    mapped += map("R") + map("F") + "00"

    PREFIX + checksum(mapped).to_s + @reference.upcase
  end

  def map(char)
    mapping.fetch(char.upcase, char.to_s).to_s
  end

  def mapping
    @mapping ||= ("A".."Z").to_a.zip((10..35).to_a).to_h
  end

  def checksum(string)
    val = 98 - (string.to_i % 97)
    val < 10 ? val.to_s.prepend("0") : val
  end

  def right_size?
    (1..21).cover?(@chars.size)
  end

  def right_chars?
    REGEXP.match(@reference)
  end
end
