# frozen_string_literal: true

#  Copyright (c) 2025, Schweizer Alpen-Club. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito

module Synchronize::Addresses::SwissPost
  class ResultProcessor
    UPDATING_QSTATS = %w[1 2 3 4]
    LOGGINGS_QSTATS = {
      "26": [:info, "Umzug ins Ausland"],
      "27": [:info, "Unbekannt weggezogen"],
      "50": [:warn, "Person an Adresse nicht bekannt"],
      "51": [:warn, "Adresse nicht bekannt"]
    }.stringify_keys

    FIELDS = {
      first_name: "Prename",
      last_name: "Name",
      address_care_of: "CoAddress",
      street: "StreetName",
      housenumber: "HouseNo",
      zip_code: "ZIPCode",
      town: "TownName"
    }

    def initialize(text)
      @data = parse(text)
    end

    def process
      each_potential_update do |person, qstat, row|
        if UPDATING_QSTATS.include?(qstat)
          update(person, row)
        elsif LOGGINGS_QSTATS.key?(qstat)
          create_log_entry(person, *LOGGINGS_QSTATS[qstat])
        end
      end
    end

    private

    attr_reader :data

    def each_potential_update
      people = Person.where(id: data.pluck("KDNR")).index_by(&:id)
      data.each do |row|
        person = people[row["KDNR"].to_i]
        yield person, row["QSTAT"], row if person
      end
    end

    def update(person, row)
      attrs = FIELDS.map do |target, source|
        [target, row[source]]
      end.to_h
      person.attributes = attrs
      person.postbox = row["POBoxTerm"].present? ? read_postbox(row) : nil

      unless person.save
        create_log_entry(person, :error,
          "Die Personendaten der Post konnten für #{person} (#{person.id}) nicht übernommen werden")
      end
    end

    def read_postbox(row)
      [
        row["POBoxTerm"],
        row["POBoxNo"].presence,
        (row["POBoxZIP"] || row["ZIPCode"]).presence,
        (row["POBoxTownName"] || row["TownName"]).presence
      ].compact_blank.join(" ")
    end

    def create_log_entry(person, level, message)
      HitobitoLogEntry.create!(
        category: Config::LOG_CATEGORY,
        subject: person,
        level:,
        message:
      )
    end

    def parse(text)
      CSV
        .parse(text, col_sep: Config::COL_SEP, row_sep: Config::ROW_SEP, headers: true)
        .delete_if { |row| row["CorrectionType"] == "0" }
        .delete_if { |row| (UPDATING_QSTATS + LOGGINGS_QSTATS.keys).exclude?(row["QSTAT"]) }
    end
  end
end
