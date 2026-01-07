#  Copyright (c) 2026, Hitobito AG. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

Fabricator(:period_invoice_template) do
  name { Faker::Company.name }
  start_on { Time.zone.yesterday }
  end_on { Time.zone.now.next_year }
  group { Group.root }
end
