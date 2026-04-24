#  Copyright (c) 2026, BdP and DPSG. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class PeriodInvoiceTemplatesController < CrudController
  self.nesting = Group

  helper_method :group, :placeholder

  self.permitted_attrs = [:name, :start_on, :end_on,
    {
      recipient_source_attributes: [:type, :group_type]
    },
    {
      items_attributes: [
        :id, :type, :name, :cost_center, :account, :vat_rate, :_destroy,
        dynamic_cost_parameters: [:unit_cost] +
          Settings.groups.period_invoice_templates.item_classes.to_h.values.flatten
      ]
    }]

  def create
    if params[:autosubmit].present?
      assign_attributes
      render "new"
    else
      super
    end
  end

  def update
    if params[:autosubmit].present?
      assign_attributes
      render "edit"
    else
      super
    end
  end

  def group = parent

  private

  def placeholder(attr, suffix: nil)
    PeriodInvoiceTemplate::Item.human_attribute_name(attr) + suffix.to_s
  end

  def assign_attributes
    super
    if entry.recipient_source.is_a?(GroupsFilter)
      entry.recipient_source.attributes = group_recipient_source_attributes
    elsif entry.recipient_source.is_a?(PeopleFilter)
      entry.recipient_source.attributes = person_recipient_source_attributes
    end
  end

  def group_recipient_source_attributes
    {
      active_at: entry.start_on,
      parent_id: entry.group_id
    }
  end

  def person_recipient_source_attributes
    {
      filter_chain: people_filter_chain,
      group_id: entry.group_id,
      range: "deep",
      visible: false
    }
  end

  def people_filter_chain
    {role: {
      role_types: [],
      kind: "active",
      start_at: entry.start_on.to_s,
      finish_at: entry.end_on.to_s,
      include_archived: true
    }}
  end
end
