# frozen_string_literal: true

#  Copyright (c) 2012-2020, CVP Schweiz. This file is part of
#  hitobito_cvp and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_cvp.

require "csv"
class Address::Importer
  # Imports Swiss addresses
  # see https://service.post.ch/zopa/dlc/app/#/main

  RECORDS = %w(01-zip_codes
               03-locations
               04-streets
               06-house_numbers
              ).freeze

  delegate :url, :token, to: "Settings.addresses"

  def run
    prepare_files if stale?
    replace_addresses
  end

  def prepare_files
    fetch_remote
    unzip_file
    write_model_files
  end

  def replace_addresses
    Address.transaction do
      Address.delete_all
      streets.to_h.values.each_slice(5_000) do |slice|
        Address.insert_all(slice)
      end
    end
  end

  def dir
    @dir ||= Rails.root.join("tmp/post")
  end

  def streets
    @streets ||= parse_streets
  end

  def house_numbers
    @house_numbers ||= parse_house_numbers
  end

  def zip_codes
    @zip_codes ||= parse_zip_codes
  end

  private

  def fetch_remote
    raise "expected token is blank" if token.blank?

    FileUtils.mkdir_p(dir)
    @response = Faraday.get(url, {}, {"Authorization" => "Basic #{token}"}).tap do |res|
      log "status: #{res.status}"
    end
  end

  def unzip_file
    Zip::InputStream.open(StringIO.new(@response.body)) do |io|
      entry = io.get_next_entry # file only has 1 entry
      log "Reading entry: #{entry.name}"
      data = io.read.force_encoding(Encoding::ISO8859_1).encode("UTF-8")
      @file = dir.join(entry.name)
      @file.write(data)
    end
  end

  def write_model_files
    records.values.each do |record|
      File.open(record[:file], "w") do |f|
        @file.each_line do |line|
          f.write(line) if line.starts_with?(record[:key].to_s)
        end
      end
    end
  end

  def parse_streets
    parse(:streets).collect do |row|
      zip_code = zip_codes.fetch(row[2])
      numbers = house_numbers.fetch(row[1], []).to_a.compact.sort.uniq
      street = {
        street_short: row[5],
        street_long: row[6],
        street_short_old: row[3],
        street_long_old: row[4],
        zip_code: zip_code[:zip],
        town: town_name(zip_code),
        state: zip_code[:state],
        numbers: numbers
      }
      [row[1], street]
    end
  end

  def town_name(zip_code)
    zip_code[:name] =~ /Lausanne\s+\d+/ ? "Lausanne" : zip_code[:name]
  end

  def parse_zip_codes
    parse(:zip_codes).collect do |row|
      [row[1], {zip: row[4], name: row[8], short_name: row[7], state: row[9]}]
    end.compact.to_h
  end

  def parse_house_numbers
    parse(:house_numbers).each_with_object({}) do |row, hash|
      next if row[3].blank?
      hash[row[2]] ||= []
      hash[row[2]] << [row[3].to_i, row[4].presence&.downcase].join
    end
  end

  def parse(key)
    file = records.dig(key, :file)
    log "parsing #{file}"
    CSV.foreach(file, col_sep: ";", quote_char: "|")
  end

  def log(*args)
    Rails.logger.tagged(self.class.name) { Rails.logger.info(*args) }
  end

  def records
    @records ||= RECORDS.collect do |model|
      key, name = model.split("-")
      [name.to_sym, {key: key, file: dir.join("#{key}-#{name}.csv")}]
    end.to_h
  end

  def stale?
    !dir.exist? || dir.ctime < 1.week.ago
  end
end
