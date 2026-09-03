# frozen_string_literal: true

#  Copyright (c) 2026, Puzzle ITC. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito

require "rails_helper"
require_relative "../../db/migrate/20260817120000_add_name_fields_to_additional_addresses"

RSpec.describe AddNameFieldsToAdditionalAddresses, type: :migration do
  let(:migration_context) { ActiveRecord::Base.connection_pool.migration_context }
  let(:migration_version) { 20260817120000 }
  let(:previous_version) do
    versions = migration_context.migrations.map(&:version)
    index = versions.index(migration_version)
    (index > 0) ? versions[index - 1] : 0
  end

  def insert_additional_address(contactable, name:, label:, uses_contactable_name: true)
    ActiveRecord::Base.connection.execute(<<~SQL)
      INSERT INTO additional_addresses
        (contactable_type, contactable_id, name, label, street, housenumber, zip_code, town,
         country, uses_contactable_name)
      VALUES
        ('#{contactable.class.base_class.sti_name}', #{contactable.id}, #{ActiveRecord::Base.connection.quote(name)},
         #{ActiveRecord::Base.connection.quote(label)}, 'Street', '1', '3000', 'Town', 'CH',
         #{uses_contactable_name})
    SQL
  end

  def additional_address_row(id)
    ActiveRecord::Base.connection.select_one(<<~SQL)
      SELECT first_name, last_name, organization_name, organization
      FROM additional_addresses WHERE id = #{id}
    SQL
  end

  before do
    SeedFu.quiet = true
    ActiveRecord::Migration.verbose = false
    migration_context.down(previous_version)
    ActiveRecord::Base.connection.schema_cache.clear!
    ActiveRecord::Base.descendants.each(&:reset_column_information)
  end

  after do
    migration_context.up
    ActiveRecord::Base.connection.schema_cache.clear!
    ActiveRecord::Base.descendants.each(&:reset_column_information)
    ActiveRecord::Migration.verbose = true
  end

  it "copies group name into organization_name and flags it as organization" do
    insert_additional_address(groups(:top_group), name: "TopGroup Office", label: "Rechnung")
    id = ActiveRecord::Base.connection.select_value("SELECT id FROM additional_addresses ORDER BY id DESC LIMIT 1")

    migration_context.up(migration_version)

    expect(additional_address_row(id)).to eq(
      "first_name" => nil,
      "last_name" => nil,
      "organization_name" => "TopGroup Office",
      "organization" => true
    )
  end

  it "copies first and last name from person when uses_contactable_name is true" do
    insert_additional_address(people(:top_leader), name: "irrelevant", label: "Arbeit")
    id = ActiveRecord::Base.connection.select_value("SELECT id FROM additional_addresses ORDER BY id DESC LIMIT 1")

    migration_context.up(migration_version)

    expect(additional_address_row(id)).to eq(
      "first_name" => "Top",
      "last_name" => "Leader",
      "organization_name" => nil,
      "organization" => false
    )
  end

  it "copies company name and company from person when uses_contactable_name is true" do
    insert_additional_address(people(:root), name: "irrelevant", label: "Rechnung")
    id = ActiveRecord::Base.connection.select_value("SELECT id FROM additional_addresses ORDER BY id DESC LIMIT 1")

    migration_context.up(migration_version)

    expect(additional_address_row(id)).to eq(
      "first_name" => nil,
      "last_name" => nil,
      "organization_name" => "Puzzle ITC",
      "organization" => true
    )
  end

  it "moves the free-text name into last_name when uses_contactable_name is false" do
    insert_additional_address(people(:top_leader), name: "Foo Bar", label: "Ferien", uses_contactable_name: false)
    id = ActiveRecord::Base.connection.select_value("SELECT id FROM additional_addresses ORDER BY id DESC LIMIT 1")

    migration_context.up(migration_version)

    expect(additional_address_row(id)).to eq(
      "first_name" => nil,
      "last_name" => "Foo Bar",
      "organization_name" => nil,
      "organization" => false
    )
  end

  it "keeps the free-text name in last_name but flags as organization when the person is a company" do
    insert_additional_address(people(:root), name: "Finance Dept", label: "Rechnung", uses_contactable_name: false)
    id = ActiveRecord::Base.connection.select_value("SELECT id FROM additional_addresses ORDER BY id DESC LIMIT 1")

    migration_context.up(migration_version)

    expect(additional_address_row(id)).to eq(
      "first_name" => nil,
      "last_name" => "Finance Dept",
      "organization_name" => "Puzzle ITC",
      "organization" => true
    )
  end

  describe "reverting" do
    def set_name_fields(id, first_name: nil, last_name: nil, organization_name: nil, organization: false)
      ActiveRecord::Base.connection.execute(<<~SQL)
        UPDATE additional_addresses
        SET first_name = #{ActiveRecord::Base.connection.quote(first_name)},
            last_name = #{ActiveRecord::Base.connection.quote(last_name)},
            organization_name = #{ActiveRecord::Base.connection.quote(organization_name)},
            organization = #{organization}
        WHERE id = #{id}
      SQL
    end

    def name_value(id)
      ActiveRecord::Base.connection.select_value("SELECT name FROM additional_addresses WHERE id = #{id}")
    end

    let!(:id) do
      insert_additional_address(people(:top_leader), name: "irrelevant", label: "Arbeit")
      ActiveRecord::Base.connection.select_value("SELECT id FROM additional_addresses ORDER BY id DESC LIMIT 1").tap do
        migration_context.up(migration_version)
      end
    end

    it "restores organization_name as name for organizations" do
      set_name_fields(id, organization_name: "Acme", organization: true)

      migration_context.down(previous_version)

      expect(name_value(id)).to eq "Acme"
    end

    it "restores joined first_name/last_name as name for individuals" do
      set_name_fields(id, first_name: "Jane", last_name: "Doe")

      migration_context.down(previous_version)

      expect(name_value(id)).to eq "Jane Doe"
    end

    it "falls back to nil when nothing is set" do
      set_name_fields(id)

      migration_context.down(previous_version)

      expect(name_value(id)).to be_nil
    end
  end
end
