# frozen_string_literal: true

#  Copyright (c) 2012-2026, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "spec_helper"
require Rails.root.join("db", "seeds", "support", "contact_account_category_seeder")

describe ContactAccountCategorySeeder do
  subject(:seeder) { described_class.new }

  describe "#seed" do
    it "adds any categories still missing but does not enqueue the migration job again" do
      expect(ContactAccountCategory.count).to be_positive
      expect(ContactAccountCategory.count).to be < ContactAccountCategorySeeder.category_count

      expect(ContactAccountCategoryMigrationJob).not_to receive(:new)
      expect { seeder.seed }.to change { ContactAccountCategory.count }
        .to(ContactAccountCategorySeeder.category_count)
    end

    it "seeds the core categories and backfills existing accounts synchronously when none exist yet" do
      ContactAccountCategory.delete_all
      email = Fabricate(:additional_email, contactable: people(:top_leader), category_id: nil,
        label: "Privat")

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
