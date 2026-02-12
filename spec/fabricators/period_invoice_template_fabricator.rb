#  Copyright (c) 2026, Hitobito AG. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

Fabricator(:period_invoice_template) do
  name { Faker::Company.name }
  start_on { Time.zone.yesterday }
  end_on { Time.zone.now.next_year }
  group { Group.root }
  before_create do |period_invoice_template|
    if period_invoice_template.items.empty?
      period_invoice_template.items.build(type: PeriodInvoiceTemplate::RoleCountItem.name, name: "Mitgliedsbeitrag",
        dynamic_cost_parameters: {unit_cost: 10, role_types: [Group::BottomLayer::Member.name]})
    end
  end
end
