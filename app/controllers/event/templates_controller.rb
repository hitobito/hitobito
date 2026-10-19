# frozen_string_literal: true

#  Copyright (c) 2026, Hitobito AG. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class Event::TemplatesController < EventsController
  self.permitted_attrs += [:inherit]
  self.sort_mappings = {name: "event_translations.name"}
  self.search_columns = []

  # cancancan would otherwise add the skip to the hash inherited from EventsController
  self._cancan_skipper = _cancan_skipper.deep_dup
  skip_authorize_resource
  before_action :authorize_class

  helper_method :group

  def self.model_class
    Event
  end

  def index
    respond_with(entries)
  end

  private

  def authorize_class
    authorize!(:index_event_templates, group)
  end

  def model_scope
    super.templates
  end

  def build_entry
    super.tap do |event|
      event.template = true
      event.groups = [group]
    end
  end

  def build_from_source
    Event
      .joins(:groups)
      .where(groups: {layer_group_id: group.id})
      .find(params[:source_id])
      .duplicate
  end

  # templates have no dates
  def build_default_dates
  end

  # templates belong to their layer only, other groups must not be selectable
  def load_sister_groups
  end

  # templates belong to their layer only, other groups must not be assignable
  def permitted_params = super.except(:group_ids)

  def list_entries
    scope = model_scope.includes(:translations)
    return scope unless sorting?

    scope.left_join_translation.reorder(Arel.sql(order_expression))
  end

  def order_expression
    return sort_expression unless params[:sort].to_s == "type"

    "#{type_order_case} #{sort_dir} NULLS LAST"
  end

  def type_order_case
    ordered_types = ([Event] + Event.subclasses).sort_by { |type| type.model_name.human }
    whens = ordered_types.each_with_index.map do |type, rank|
      condition = (type == Event) ? "IS NULL" : "= #{Event.connection.quote(type.sti_name)}"
      "WHEN events.type #{condition} THEN #{rank}"
    end.join(" ")
    "CASE #{whens} END"
  end

  def form_url
    entry.new_record? ? group_event_templates_path(group) : group_event_template_path(group, entry)
  end

  def cancel_url = index_path

  def return_path = index_path

  def index_path = group_event_templates_path(group)
end
