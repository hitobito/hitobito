# frozen_string_literal: true

#  Copyright (c) 2012-2026, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class AddNameFieldsToAdditionalAddresses < ActiveRecord::Migration[7.1]
  def up
    add_column :additional_addresses, :first_name, :string
    add_column :additional_addresses, :last_name, :string
    add_column :additional_addresses, :organization_name, :string
    add_column :additional_addresses, :organization, :boolean, null: false, default: false

    migrate_group_addresses
    migrate_contactable_name_addresses
    migrate_free_text_addresses

    remove_column :additional_addresses, :name, :string
  end

  def down
    add_column :additional_addresses, :name, :string

    restore_name_from_name_fields

    remove_column :additional_addresses, :first_name
    remove_column :additional_addresses, :last_name
    remove_column :additional_addresses, :organization_name
    remove_column :additional_addresses, :organization
  end

  private

  # Leaves name nil when neither organization_name nor first_name/last_name is set, rather than
  # restoring the original not-null constraint, since down migrations only need to leave the app
  # in a usable state, not exactly mirror the original schema.
  def restore_name_from_name_fields
    execute(<<~SQL)
      UPDATE additional_addresses
      SET name = NULLIF(
        CASE
          WHEN organization AND organization_name IS NOT NULL AND organization_name <> ''
            THEN organization_name
          ELSE TRIM(BOTH ' ' FROM (COALESCE(first_name, '') || ' ' || COALESCE(last_name, '')))
        END,
        ''
      )
    SQL
  end

  def migrate_group_addresses
    execute(<<~SQL)
      UPDATE additional_addresses
      SET organization_name = name, organization = TRUE, first_name = NULL, last_name = NULL
      WHERE contactable_type = 'Group'
    SQL
  end

  def migrate_contactable_name_addresses
    execute(<<~SQL)
      UPDATE additional_addresses aa
      SET first_name = people.first_name, last_name = people.last_name,
          organization_name = people.company_name, organization = people.company
      FROM people
      WHERE aa.contactable_type = 'Person'
        AND aa.contactable_id = people.id
        AND aa.uses_contactable_name = TRUE
    SQL
  end

  def migrate_free_text_addresses
    # Keep the free-text name in last_name, but still flag as an organization when the
    # contactable itself is a company, so Contactable::Address#company? (now read from the
    # additional address instead of the contactable) keeps honoring the company name.
    execute(<<~SQL)
      UPDATE additional_addresses aa
      SET first_name = NULL,
          last_name = aa.name,
          organization_name = CASE
            WHEN people.company AND NULLIF(people.company_name, '') IS NOT NULL THEN people.company_name
            ELSE NULL
          END,
          organization = (people.company AND NULLIF(people.company_name, '') IS NOT NULL)
      FROM people
      WHERE aa.contactable_type = 'Person'
        AND aa.contactable_id = people.id
        AND aa.uses_contactable_name = FALSE
    SQL
  end
end
