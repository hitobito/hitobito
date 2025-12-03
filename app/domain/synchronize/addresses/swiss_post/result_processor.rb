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

    CSV_OPTIONS = {
      col_sep: Config::COL_SEP,
      row_sep: Config::ROW_SEP,
      headers: true,
      liberal_parsing: true
    }

    def initialize(text, invalid_tag)
      @data = parse(text)
      @invalid_tag = invalid_tag
      @updated_people_ids = []
    end

    def process
      each_potential_update do |person, qstat, row|
        if UPDATING_QSTATS.include?(qstat)
          update(person, row)
        elsif LOGGINGS_QSTATS.key?(qstat)
          create_log_entry(person, *LOGGINGS_QSTATS[qstat])
        end
      end
      destroy_obsolete_taggings
    end

    private

    attr_reader :data, :invalid_tag, :updated_people_ids

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

      if person.save
        updated_people_ids << person.id
      else
        create_tag_and_log_error(person)
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

    def create_tag_and_log_error(person)
      message = "Die Personendaten der Post konnten für #{person} (#{person.id}) nicht " \
        "übernommen werden"
      create_log_entry(person, :error, message)
      create_tag(person.taggings, message, invalid_tag)
    end

    def create_tag(taggings, message, tag)
      taggings.find_or_create_by!(tag:, context: :tags).tap do |tagging|
        tagging.update!(hitobito_tooltip: message)
      end
    end

    def destroy_obsolete_taggings
      invalid_tag.taggings.where(
        taggable_id: updated_people_ids,
        taggable_type: "Person"
      ).destroy_all
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
        .parse(text, **CSV_OPTIONS)
        .delete_if { |row| row["CorrectionType"] == "0" }
        .delete_if { |row| (UPDATING_QSTATS + LOGGINGS_QSTATS.keys).exclude?(row["QSTAT"]) }
    end
  end
end
