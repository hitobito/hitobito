# frozen_string_literal: true

#  Copyright (c) 2012-2020, CVP Schweiz. This file is part of
#  hitobito_cvp and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_cvp.

class Address::Parser

  REGEX = /^(.*?)[,?\s*]?(\d+\s?\w?)?$/.freeze

  def initialize(string)
    @string = string.gsub(",", "")
  end

  def street
    match[1]
  end

  def number
    match[2]&.gsub(" ", "")
  end

  def parse
    [street, number]
  end

  private

  def match
    @match ||= REGEX.match(@string)
  end

end
