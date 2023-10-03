# frozen_string_literal: true

#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require 'csv'

module Import
  class CsvParser
    include Translatable
    extend Forwardable

    def_delegators :csv, :size, :first, :to_csv, :[], :each
    attr_reader :csv, :error
    POSSIBLE_SEPARATORS = [',', "\t", ':', ';']

    def initialize(input)
      @input = input
    end

    def parse
      begin
        data = encode_as_utf8(@input)
        separator = find_separator(data)
        sanitized = remove_empty_lines(data, separator)
        @csv = CSV.parse(sanitized, **options.merge(col_sep: separator))
      rescue => e
        @error = e.to_s
      end
      error.blank?
    end

    def map_data(header_mapping)
      if header_mapping.is_a?(ActionController::Parameters)
        header_mapping = header_mapping.to_unsafe_h
      end
      header_mapping = header_mapping.with_indifferent_access
      header_mapping.reject! { |_key, value| value.blank? }
      csv.map do |row|
        csv.headers.each_with_object({}) do |name, object|
          key = header_mapping[name]
          object[key] = row[name] if key.present?
        end
      end
    end

    def headers
      csv.headers.reject(&:blank?)
    end

    def flash_notice
      translate(:read_success, count: size)
    end

    def flash_alert(filename = 'csv formular daten')
      translate(:read_error, filename: filename, error: error)
    end

    private

    def options
      { converters: ->(field, _info) { field && field.strip },
        header_converters: ->(header, _info) { header.to_s.strip },
        headers: true, skip_blanks: true }
    end

    def encode_as_utf8(input)
      raise translate(:contains_no_data) if input.nil?
      unless input.valid_encoding?
        input = input.encode('UTF-8', invalid: :replace, undef: :replace)
      end
      input
    end

    # removes empty lines (",,,,,\n"), happens when data is not on first line in spreadsheet
    def remove_empty_lines(raw, separator)
      raw.lines.reject { |line| line.strip.split(separator).all?(&:empty?) }.join
    end

    def find_separator(input)
      start = input[0..500]
      POSSIBLE_SEPARATORS.inject do |most_seen, char|
        start.count(char) > start.count(most_seen) ? char : most_seen
      end
    end

  end
end
