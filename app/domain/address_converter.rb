# frozen_string_literal: true

#  Copyright (c) 2024, Puzzle ITC. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class AddressConverter
  STREET_HOUSENUMBER_REGEX = %r{^(.*?)[,?[:space:]*]?((?:\d+[-/])?\d+\s?\w?)?$}

  # complete flow for one contactable, with callbacks to be used from a rake-task
  def self.convert(contactable, success:, incomplete:, failed:) # rubocop:disable Metrics/MethodLength,Metrics/CyclomaticComplexity,Metrics/PerceivedComplexity
    conv = new(contactable)
    conv.split

    if conv.check
      begin
        result = conv.save
        success&.call()
      rescue
        result = false
        failed&.call(conv.failed_info)
      end

      result
    else
      failed&.call(conv.failed_info) if conv.failed?
      incomplete&.call(conv.incomplete_info) if conv.incomplete?

      false
    end
  end

  def initialize(contactable)
    @contactable = contactable # person or group

    @addr = @contactable[:address]
  end

  def split
    return @contactable if only_question_marks?

    extract_address_field_from(sanitized_address_lines)

    @contactable
  end

  def check
    same_address? ||
    same_complete_address? ||
    better_address? ||
    address_with_question_marks? ||
    only_question_marks?
  end

  def save
    @contactable.address = nil
    @contactable.save(validate: false)
  end

  def failed?
    structured_address.values.compact.blank?
  end

  def failed_info
    incomplete_info[0..1]
  end

  def incomplete?
    !check && !failed?
  end

  def incomplete_info
    [@contactable.id, @addr, structured_address]
  end

  private

  # preparation

  def sanitized_address_lines
    @addr.lines
         .map { |line| line.gsub(/[[:space:]]+/, ' ').gsub(/\?+$/, '').strip.chomp }
         .reject { |line| line.empty? }
  end

  # parsing / extraction

  def extract_address_field_from(lines) # rubocop:disable Metrics/MethodLength,Metrics/CyclomaticComplexity,Metrics/AbcSize
    case lines.count
    when 1
      only_street_and_number(lines.first)
    when 2
      if address_in_line(lines.last) # has side effect
        @contactable.address_care_of = lines.first.strip
      elsif address_in_line(lines.first)
        @contactable.postbox = lines.last.strip
      else
        only_street_and_number(lines.join(' '))
      end
    when 3
      if address_in_line(lines[1])
        @contactable.address_care_of = lines.first.strip
        @contactable.postbox = lines.last.strip
      end
    end
  end

  def address_in_line(line)
    only_street_and_number(line)
    return true if line == @contactable.address

    @contactable.restore_attributes(%w(street housenumber))

    false
  end

  def only_street_and_number(line)
    matches = STREET_HOUSENUMBER_REGEX.match(line)
    @contactable.street = matches[1]&.strip
    @contactable.housenumber = matches[2]&.strip

    matches
  end

  # helper for checks

  def structured_address
    {
      care_of: @contactable.address_care_of,
      street: @contactable.street,
      number: @contactable.housenumber,
      postbox: @contactable.postbox
    }
  end

  def new_address
    [
      @contactable.address_care_of,
      @contactable.address,
      @contactable.postbox
    ].compact
  end

  def sanitized_address
    @addr.lines
         .map { |line| line.gsub(/[[:space:]]+/, ' ').strip }
         .reject { |line| line.empty? }
         .join("\n")
         .chomp(',')
  end

  # checks

  def same_address?
    sanitized_address == @contactable.address
  end

  def same_complete_address?
    sanitized_address == new_address.join("\n")
  end

  def better_address?
    sanitized_address == [@contactable.street, @contactable.housenumber].join ||
    sanitized_address == [@contactable.street, @contactable.housenumber].join(',')
  end

  def address_with_question_marks?
    sanitized_address.gsub(/\?+$/, '').strip == @contactable.address
  end

  def only_question_marks?
    @addr =~ /^\?+$/
  end
end
