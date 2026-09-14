# frozen_string_literal: true

#  Copyright (c) 2026, Hitobito AG. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class AddCantonToPeople < ActiveRecord::Migration[8.0]

  def up
    add_column :people, :canton, :string, null: true unless column_exists?(:people, :canton)
    Person.reset_column_information

    # Order-dependent: each step relies on the cleanup done by the ones before it.
    normalize_canton_values
    recover_full_text_canton_values if name_code_values_sql.present?
    clear_invalid_canton_values
    clear_canton_for_non_swiss_people

    Migrations::SetCantonFromZipCodeJob.new.enqueue!
  end

  def down
    # Not exactly right for cevi/insieme/jubla/sac_cas, whose own historical migrations
    # added this column independently of this one - but better than raising
    # ActiveRecord::IrreversibleMigration.
    remove_column :people, :canton
    Person.reset_column_information
  end

  private

  def normalize_canton_values
    Person.where.not(canton: nil).update_all("canton = NULLIF(TRIM(LOWER(canton)), '')")
  end

  def recover_full_text_canton_values
    short_codes_sql = Cantons.short_name_strings.map { |c| connection.quote(c) }.join(", ")
    execute(<<~SQL)
      UPDATE people
      SET canton = name_code_mapping.code
      FROM (VALUES #{name_code_values_sql}) AS name_code_mapping(name, code)
      WHERE people.canton IS NOT NULL
        AND people.canton NOT IN (#{short_codes_sql})
        AND #{normalize_canton_text_sql("people.canton")} = name_code_mapping.name
    SQL
  end

  def clear_invalid_canton_values
    Person.where.not(canton: nil)
      .where.not(canton: Cantons.short_name_strings)
      .update_all(canton: nil)
  end

  def clear_canton_for_non_swiss_people
    condition = if Countries.default == "ch"
      "country IS NOT NULL AND TRIM(UPPER(country)) NOT IN ('', 'CH')"
    else
      "country IS NULL OR TRIM(UPPER(country)) <> 'CH'"
    end

    Person.where.not(canton: nil).where(condition).update_all(canton: nil)
  end

  def name_code_values_sql
    @name_code_values_sql ||= begin
      name_code_mapping = Cantons.short_name_strings.product([:de, :fr, :it, :en]).map do |code, locale|
        label = I18n.t("activerecord.attributes.cantons.#{code}", locale: locale, default: nil)
        [normalize_canton_text(label), code] if label.present?
      end

      name_code_mapping.to_h.map do |name, code|
        "(#{connection.quote(name)}, #{connection.quote(code)})"
      end.join(", ").presence
    end
  end

  def normalize_canton_text(str)
    str.downcase.gsub(/[-.\s]+/, " ").strip
  end

  def normalize_canton_text_sql(column)
    "lower(trim(regexp_replace(#{column}, '[-.[:space:]]+', ' ', 'g')))"
  end

end
