# encoding: utf-8

#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class Event::RolesController < CrudController
  require_relative '../../decorators/event/role_decorator'

  self.nesting = Group, Event

  self.permitted_attrs = [:label]

  decorates :event_role, :event, :group

  # load group before authorization
  prepend_before_action :parent, :group

  def create
    assign_attributes
    new_participation = entry.participation.new_record?
    created = with_callbacks(:create, :save) { save_entry }
    url = if new_participation && created
            edit_group_event_participation_path(group, event, entry.participation)
          else
            group_event_participations_path(group, event)
          end
    respond_with(entry, success: created, location: url)
  end

  def update
    super(location: group_event_participation_path(group, event, entry.participation_id))
  end

  def destroy
    super(location: group_event_participations_path(group, event))
  end

  private

  def build_entry
    attrs = params[:event_role]
    type =  attrs && attrs[:type]
    role = parent.class.find_role_type!(type).new

    # delete unused attributes
    attrs.delete(:event_id)
    attrs.delete(:person)

    role.participation = parent.participations.where(person_id: attrs.delete(:person_id)).
                                               first_or_initialize
    role.participation.init_answers if role.participation.new_record?

    role
  end

  # A label for the current entry, including the model name, used for flash
  def full_entry_label
    translate(:full_entry_label, role: h(entry),
                                 person: h(entry.participation.person),
                                 event: h(entry.participation.event)).html_safe
  end

  def event
    parent
  end

  def group
    @group ||= parents.first
  end

  def parent_scope
    model_class
  end

  # model_params may be empty
  def permitted_params
    model_params.permit(permitted_attrs)
  end

  class << self
    def model_class
      Event::Role
    end
  end

end
