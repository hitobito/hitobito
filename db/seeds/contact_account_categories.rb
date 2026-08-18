#  Copyright (c) 2012-2026, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

if !Rails.env.test? # categories are provided via fixtures in tests
  require Rails.root.join("db", "seeds", "support", "contact_account_category_seeder")
  ContactAccountCategorySeeder.new.seed
end
