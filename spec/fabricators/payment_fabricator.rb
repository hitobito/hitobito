# frozen_string_literal: true

#  Copyright (c) 2026-2026, Schweizer Wanderwege. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

Fabricator(:payment) do
  invoice { Fabricate(:invoice) }
  amount { Faker::Number.decimal(l_digits: 2, r_digits: 2) }
  received_at { 1.week.ago.to_date }
  reference { Faker::Invoice.reference }
  transaction_identifier { Faker::Internet.uuid }
  status { "manually_created" }
end
