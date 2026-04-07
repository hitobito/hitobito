# frozen_string_literal: true

#  Copyright (c) 2025, Schweizer Alpen-Club. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito

module Synchronize::Addresses::SwissPost
  class Generator
    class_attribute :fields, default: {
      CustomID_01_in: nil,
      Company_in: :company,
      Prename_in: :first_name,
      Prename2_in: nil,
      Name_in: :last_name,
      MaidenName_in: nil,
      AddressAddition_in: nil,
      CoAddress_in: :address_care_of,
      StreetName_in: :street,
      HouseNo_in: :housenumber,
      HouseNoAddition_in: :housenumber_addition,
      Floor_in: nil,
      ZIPCode_in: :zip_code,
      ZIPAddition_in: nil,
      TownName_in: :town,
      Canton_in: nil,
      CountryCode_in: :country,
      PoBoxTerm_in: nil,
      PoBoxNo_in: nil,
      PoBoxZIP_in: nil,
      PoBoxZIPAddition_in: nil,
      PoBoxTownName_in: nil,
      PassThrough_01: :id,
      PassThrough_02: nil,
      PassThrough_03: nil,
      PassThrough_04: nil,
      PassThrough_05: nil,
      PassThrough_06: nil,
      PassThrough_07: nil,
      PassThrough_08: nil,
      PassThrough_09: nil,
      PassThrough_10: nil
    }

    HOUSENUMBER_REGEX = /(\d+)\s?([a-zA-Z]+)?/

    def initialize(scope, invalid_tag)
      @scope = scope
      @invalid_tag = invalid_tag
    end

    def generate
      data.encode(Config.encoding)
    end

    private

    attr_reader :invalid_tag, :scope

    def data
      CSV.generate(col_sep: Config::COL_SEP, row_sep: Config::ROW_SEP) do |csv|
        csv << fields.keys

        scope.find_each do |person|
          values = values_from(person)
          csv << values if values
        end
      end
    end

    def values_from(person) # rubocop:disable Metrics/CyclomaticComplexity
      values = fields.values.map do |field|
        next field if field.nil?
        respond_to?(field, true) ? send(field, person) : person.send(field)
      end

      values if values.all? { |v| v.to_s.encode(Config.encoding) }
    rescue Encoding::UndefinedConversionError
      handle_conversion_error(person)
      false
    end

    def handle_conversion_error(person)
      message = "Die Personendaten zu #{person}(#{person.id}) konnten nicht übertragen werden"
      create_log_entry(person, message)
      create_tag(person.taggings, message, invalid_tag)
    end

    def create_tag(taggings, message, tag)
      taggings.find_or_create_by!(tag:, context: :tags).tap do |tagging|
        tagging.update!(hitobito_tooltip: message)
      end
    end

    def create_log_entry(person, message)
      HitobitoLogEntry.create!(
        category: Config::LOG_CATEGORY,
        subject: person,
        level: :warn,
        message:
      )
    end

    def housenumber(person)
      person.housenumber.to_s[HOUSENUMBER_REGEX, 1]
    end

    def housenumber_addition(person)
      person.housenumber.to_s[HOUSENUMBER_REGEX, 2]
    end

    def company(person)
      person.company_name if person.company
    end
  end
end
