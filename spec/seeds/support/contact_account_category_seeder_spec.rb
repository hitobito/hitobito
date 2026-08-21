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
    it "does nothing if any category already exists (fixtures already provide the core set)" do
      expect(ContactAccountCategory.count).to be_positive

      expect(ContactAccountCategoryMigrationJob).not_to receive(:new)
      expect { seeder.seed }.not_to change { ContactAccountCategory.count }
    end

    it "seeds the core categories and enqueues the migration job when none exist yet" do
      ContactAccountCategory.delete_all

      expect { seeder.seed }.to change { ContactAccountCategory.count }
        .from(0).to(ContactAccountCategorySeeder::CATEGORIES.size)

      job = Delayed::Job.all.find { |j| j.name == "ContactAccountCategoryMigrationJob" }
      expect(job).to be_present
    end
  end
end
