# frozen_string_literal: true

#  Copyright (c) 2012-2026, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "spec_helper"
require Rails.root.join("db", "seeds", "support", "contact_account_category_seeder")

describe ContactAccountCategorySeeder do
  subject(:seeder) { described_class.new }

  before do
    SeedFu.quiet = true

    # category_id is NOT NULL in the real schema -- loosened here so the
    # "not yet categorized" row below can be nulled out at all, simulating a
    # not-yet-migrated install. Rolled back automatically with everything else
    # in the example (Postgres DDL is transactional, and spec_helper runs each
    # example inside one transaction).
    ActiveRecord::Base.connection.change_column_null(:additional_emails, :category_id, true)
  end

  describe ".insert_before" do
    it "inserts entries before the given key and removes them again" do
      list = ContactAccountCategorySeeder::CATEGORIES["PhoneNumber"]["Person"]
      original_size = list.size
      original_keys = list.map { |item| item[:key] }
      other_index = original_keys.index("other")

      ContactAccountCategorySeeder.insert_before("PhoneNumber", "Person", "other",
                                                 {key: "test_a", name: {de: "Test A"}},
                                                 {key: "test_b", name: {de: "Test B"}})

      expect(list.map { |item| item[:key] })
        .to eq original_keys.insert(other_index, "test_a", "test_b")

      list.delete_if { |item| %w[test_a test_b].include?(item[:key]) }
      expect(list.size).to eq original_size
    end

    it "appends entries when the given key is missing" do
      list = ContactAccountCategorySeeder::CATEGORIES["PhoneNumber"]["Person"]
      original_size = list.size

      ContactAccountCategorySeeder.insert_before("PhoneNumber", "Person", "missing",
                                                 {key: "test_c", name: {de: "Test C"}})

      expect(list.last[:key]).to eq "test_c"

      list.delete_if { |item| item[:key] == "test_c" }
      expect(list.size).to eq original_size
    end
  end

  describe "#seed" do
    it "adds any categories still missing but does not enqueue the migration job again" do
      expect(ContactAccountCategory.count).to be_positive
      expect(ContactAccountCategory.count).to be < ContactAccountCategorySeeder.category_count

      expect(ContactAccountCategoryMigrationJob).not_to receive(:new)
      expect { seeder.seed }.to change { ContactAccountCategory.count }
        .to(ContactAccountCategorySeeder.category_count)
    end

    it "seeds the core categories and backfills existing accounts synchronously when none exist yet" do
      # category is required by validation now, so this can't be fabricated
      # with category_id: nil directly once the categories table is already
      # empty (the fabricator's own default relies on a category existing to
      # assign) -- fabricate normally first, then null it out and empty the
      # table, simulating a not-yet-migrated row on an otherwise-uninitialized
      # install.
      email = Fabricate(:additional_email, contactable: people(:top_leader), label: "Privat")
      email.update_column(:category_id, nil)
      ContactAccountCategory.delete_all

      expect { seeder.seed }.to change { ContactAccountCategory.count }
        .from(0).to(ContactAccountCategorySeeder.category_count)

      expect(Delayed::Job.all).to be_empty
      private_category = ContactAccountCategory.find_by(contact_account_type: "AdditionalEmail",
        contactable_type: "Person", key: "private")
      expect(email.reload.category).to eq private_category
      expect(email.label).to be_nil
    end
  end
end
