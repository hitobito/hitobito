# frozen_string_literal: true

#  Copyright (c) 2026, Hitobito AG. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class Event::TemplatesController < ListController
  self.nesting = Group
  self.sort_mappings = {name: "event_translations.name"}

  decorates :events

  helper_method :group

  def self.model_class
    Event
  end

  private

  def authorize_class
    authorize!(:index_event_templates, group)
  end

  def list_entries
    scope = group.events.templates.includes(:translations)
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

  def group = @group ||= parent
end
