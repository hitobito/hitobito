# == Schema Information
#
# Table name: period_invoice_templates
#
#  id                    :integer          not null, primary key
#  name                  :string           not null
#  start_on              :date             not null
#  end_on                :date
#  recipient_group_type  :string
#  group_id              :integer          not null
#  created_at            :datetime         not null
#  updated_at            :datetime         not null
#  recipient_source_type :string
#  recipient_source_id   :integer
#
# Indexes
#
#  index_period_invoice_templates_on_group_id          (group_id)
#  index_period_invoice_templates_on_recipient_source  (recipient_source_type,recipient_source_id)
#

#  Copyright (c) 2026, Hitobito AG. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

Fabricator(:period_invoice_template) do
  name { Faker::Company.name }
  start_on { Time.zone.yesterday }
  end_on { Time.zone.now.next_year }
  group { Group.root }
  recipient_group_type { Group::BottomLayer.name }
  recipient_source {
    GroupsFilter.new(parent: Group.root, group_type: Group::BottomLayer.name, active_at: Time.zone.today)
  }
  before_create do |period_invoice_template|
    if period_invoice_template.items.empty?
      period_invoice_template.items.build(type: PeriodInvoiceTemplate::RoleCountItem.name, name: "Mitgliedsbeitrag",
        dynamic_cost_parameters: {unit_cost: "5", role_types: [Group::BottomLayer::LocalGuide.name]})
    end
  end
end
