# encoding: utf-8

#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class Event::RolesController < CrudController

  self.nesting = Group, Event

  self.permitted_attrs = [:label]

  decorates :event_role, :event, :group

  # load group before authorization
  prepend_before_action :parent, :group

  before_render_edit :possible_types

  def create
    assign_attributes
    new_participation = entry.participation.new_record?
    created = with_callbacks(:create, :save) { save_entry }
    respond_with(entry, success: created, location: after_create_url(new_participation, created))
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
    type = attrs && attrs[:type]
    role = event.class.find_role_type!(type).new

    # delete unused attributes
    attrs.delete(:event_id)
    attrs.delete(:person)

    role.participation = event.participations.where(person_id: attrs.delete(:person_id)).
                                              first_or_initialize
    role.participation.init_answers if role.participation.new_record?

    role
  end

  def assign_attributes
    set_type if entry.persisted?
    super
  end

  def set_type
    type = model_params && model_params.delete(:type)
    if type && possible_types.collect(&:sti_name).include?(type)
      entry.type = type
    end
  end

  # A label for the current entry, including the model name, used for flash
  def full_entry_label
    translate(:full_entry_label, role: h(entry),
                                 person: h(entry.participation.person)).html_safe
  end

  def after_create_url(new_participation, created)
    if new_participation && created
      edit_group_event_participation_path(group, event, entry.participation)
    else
      group_event_participations_path(group, event)
    end
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

  def possible_types
    @possible_types ||=
      if entry.restricted?
        event.class.participant_types
      else
        event.class.role_types.reject(&:restricted?)
      end
  end

  class << self
    def model_class
      Event::Role
    end
  end

end
