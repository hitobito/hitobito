# frozen_string_literal: true

#  Copyright (c) 2026, Puzzle ITC. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "rails_helper"
require_relative "../../db/migrate/20260818090000_add_contact_account_categories"

RSpec.describe AddContactAccountCategories, type: :migration do
  let(:migration_context) { ActiveRecord::Base.connection_pool.migration_context }
  let(:migration_version) { 20260818090000 }
  let(:previous_version) do
    versions = migration_context.migrations.map(&:version)
    index = versions.index(migration_version)
    (index > 0) ? versions[index - 1] : 0
  end

  before do
    ActiveRecord::Migration.verbose = false
    migration_context.down(previous_version)
    clear_contact_account_records!
    ActiveRecord::Base.connection.schema_cache.clear!
    ActiveRecord::Base.descendants.each(&:reset_column_information)
  end

  after do
    clear_contact_account_records!
    migration_context.up
    ActiveRecord::Base.connection.schema_cache.clear!
    ActiveRecord::Base.descendants.each(&:reset_column_information)
    ActiveRecord::Migration.verbose = true
  end

  def clear_contact_account_records!
    %i[additional_addresses additional_emails phone_numbers social_accounts].each do |table|
      ActiveRecord::Base.connection.execute("DELETE FROM #{table}")
    end
  end

  def create_category(contact_account_type, contactable_type, key, de_name)
    category = ContactAccountCategory.new(
      contact_account_type: contact_account_type,
      contactable_type: contactable_type,
      key: key,
      position: 0,
      unique_per_contactable: key != "other",
      used_for_invoices: false
    )
    category.name_de = de_name
    category.save!
    category
  end

  def insert_record(table, category, label:)
    columns = {
      contactable_type: "Person",
      contactable_id: people(:top_leader).id,
      category_id: category.id,
      label: label
    }

    case table
    when :additional_addresses
      columns.merge!(
        street: "Street",
        zip_code: "3000",
        town: "Town",
        country: "CH",
        public: false,
        uses_contactable_name: true,
        invoices: false
      )
    when :additional_emails
      columns.merge!(email: "test@example.com", public: true, mailings: true)
    when :phone_numbers
      columns.merge!(number: "+41 79 000 00 00", public: true)
    when :social_accounts
      columns.merge!(name: "example", public: true)
    end

    values = columns.values.map { |v| ActiveRecord::Base.connection.quote(v) }.join(", ")

    ActiveRecord::Base.connection.select_value(<<~SQL)
      INSERT INTO #{table} (#{columns.keys.join(", ")})
      VALUES (#{values})
      RETURNING id
    SQL
  end

  def label_for(table, id)
    ActiveRecord::Base.connection.select_value(<<~SQL)
      SELECT label FROM #{table} WHERE id = #{id}
    SQL
  end

  it "backfills missing labels from the category name and appends id only to additional_addresses" do
    clear_contact_account_records!
    migration_context.up(migration_version)

    other = create_category("AdditionalAddress", "Person", "other", "Andere")

    address_id = insert_record(:additional_addresses, other, label: nil)
    email_id = insert_record(:additional_emails, other, label: nil)
    phone_id = insert_record(:phone_numbers, other, label: nil)
    social_id = insert_record(:social_accounts, other, label: " ")

    migration_context.down(previous_version)

    expect(label_for(:additional_addresses, address_id)).to match(/\AAndere-\d+\z/)
    expect(label_for(:additional_emails, email_id)).to eq "Andere"
    expect(label_for(:phone_numbers, phone_id)).to eq "Andere"
    expect(label_for(:social_accounts, social_id)).to eq "Andere"
  end

  it "keeps existing labels for non-address tables" do
    clear_contact_account_records!
    migration_context.up(migration_version)

    other = create_category("AdditionalEmail", "Person", "other", "Andere")
    email_id = insert_record(:additional_emails, other, label: "Ferien")

    migration_context.down(previous_version)

    expect(label_for(:additional_emails, email_id)).to eq "Ferien"
  end

  it "suffixes existing labels with the id for additional_addresses" do
    clear_contact_account_records!
    migration_context.up(migration_version)

    other = create_category("AdditionalAddress", "Person", "other", "Andere")
    address_id = insert_record(:additional_addresses, other, label: "Ferien")

    migration_context.down(previous_version)

    expect(label_for(:additional_addresses, address_id)).to match(/\AFerien-\d+\z/)
  end
end
