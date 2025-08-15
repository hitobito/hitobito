# frozen_string_literal: true

#  Copyright (c) 2025, Schweizer Alpen-Club. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito

module Synchronize::Addresses::SwissPost
  class Generator
    FIELDS = {
      id: "KDNR (QSTAT)",
      company: "Firma",
      first_name: "Vorname",
      last_name: "Nachname",
      address_care_of: "c/o",
      street: "Strasse",
      housenumber: "Hausnummer",
      postbox: "Postfach",
      zip_code: "PLZ",
      town: "Ort"
    }

    def initialize(scope)
      @scope = scope
    end

    def generate
      data.encode(Config::ENCODING)
    end

    private

    def data
      CSV.generate(col_sep: Config::COL_SEP, row_sep: Config::ROW_SEP) do |csv|
        csv << FIELDS.values

        @scope.find_each do |person|
          values = values_from(person)
          csv << values if values
        end
      end
    end

    def values_from(person)
      values = FIELDS.keys.map do |key|
        respond_to?(key, true) ? send(key, person) : person.send(key)
      end

      values if values.all? { |v| v.to_s.encode(Config::ENCODING) }
    rescue Encoding::UndefinedConversionError
      HitobitoLogEntry.create!(
        category: Config::LOG_CATEGORY,
        subject: person,
        level: :warn,
        message: "Die Personendaten zu #{person}(#{person.id}) konnten nicht übertragen werden"
      )

      false
    end

    def company(person)
      person.company_name if person.company
    end
  end
end
