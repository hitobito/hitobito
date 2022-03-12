# frozen_string_literal: true

#  Copyright (c) 2022, Pfadibewegung Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class CalendarsController < CrudController

  helper_method :group

  self.nesting = Group

  self.permitted_attrs = [:name, :description,
                          {
                              included_calendar_groups_attributes: [
                                  :id, :group_id, :excluded, :with_subgroups, :event_type, :_destroy
                              ],
                              excluded_calendar_groups_attributes: [
                                  :id, :group_id, :excluded, :with_subgroups, :event_type, :_destroy
                              ],
                          }]

  decorates :group

  prepend_before_action :parent
  before_render_form :possible_tags

  def feed
    # TODO check token, find events, output them in ics format
  end

  def new(&block)
    assign_attributes if model_params
    entry.included_calendar_groups.build(group: group) if entry.included_calendar_groups.blank?
    respond_with(entry, &block)
  end

  private

  alias group parent

  def authorize_class
    authorize!(:index_calendars, group)
  end

  def assign_attributes
    super
    if model_params
      entry.calendar_tags = calendar_tags
    end
  end

  def possible_tags
    @possible_tags ||= Event.tags_on(:tags).order(:name).collect do |tag|
      [tag.name, tag.id]
    end
  end

  def calendar_tags
    (
      included_tags.map { |id| CalendarTag.new(tag_id: id, excluded: false) } +
      excluded_tags.map { |id| CalendarTag.new(tag_id: id, excluded: true) }
    ).compact
  end

  def included_tags
    model_params[:included_calendar_tags_ids]&.reject(&:empty?) || []
  end

  def excluded_tags
    model_params[:excluded_calendar_tags_ids]&.reject(&:empty?) || []
  end

end
