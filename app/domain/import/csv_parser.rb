# encoding: UTF-8
require 'csv'
require 'cmess/guess_encoding'

module Import
  class CsvParser
    extend Forwardable
    def_delegators :csv, :size, :headers, :first, :to_csv
    attr_reader :csv, :error

    def initialize(input)
      @input = input
    end

    def parse
      begin
        data = encode_as_utf8(@input)
        @csv = CSV.parse(data, col_sep: find_seperator(data), headers: true)
      rescue Exception => e
        @error = e.to_s
      end
      !@error.present?
    end

    def map_headers(mapping)
      csv.map do |row|
        headers.each_with_object({}) do |header, object|
          key = mapping.with_indifferent_access[header]
          object[key] = row[header]
        end
      end
    end

    def valid?
      error.nil?
    end

    def flash_notice
      text = size > 1 ? "#{size} Datensätze"  : "#{size} Datensatz"
      text += " erfolgreich gelesen."
    end

    def flash_alert(filename="csv formular daten")
      "Fehler beim Lesen von #{filename}: #{error}"
    end

    private
    def encode_as_utf8(input)
      charset = CMess::GuessEncoding::Automatic.guess(input)
      charset = Encoding::ISO8859_1 if charset == "MACINTOSH"
      input.force_encoding(charset).encode("UTF-8")
    end
 
    def find_seperator(input)
      start = input[0..500]
      ["\s", "\t", ':', ';'].inject(',') do |most_seen,char|
        start.count(char) > start.count(most_seen) ? char : most_seen
      end
    end
  end
end 
