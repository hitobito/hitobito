#  Copyright (c) 2018, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class Event::ParticipationListsController < SimpleCrudController
  include FilteredPeople # provides all_filtered_or_listed_people, person_filter, list_filter_args

  skip_authorization_check
  skip_authorize_resource

  respond_to :js, only: :new

  helper_method :group

  def create
    new_participations = build_new_participations
    success = ActiveRecord::Base.transaction do
      raise ActiveRecord::Rollback unless new_participations.all?(&:save)
      true
    end

    flash_key = success ? :notice : :alert
    redirect_to(group_people_path(group, list_filter_params),
      flash_key => flash_message(success ? :success : :failure, count: new_participations.count))
  end

  def new
    @people_ids ||= params[:ids]
    @event_type = params[:type]
    @event_label = params[:label]
    render "new"
  end

  def self.model_class
    Event::Participation
  end

  private

  def build_new_participations
    people.filter_map do |person|
      participation = build_participation(person)
      next if participation.roles.any? { |role| role.type == role_type.sti_name }

      role = role_type.new(participation: participation)
      participation if can?(:create, role)
    end
  end

  def build_participation(person)
    Event::Participation.find_or_initialize_by(
      event: event,
      participant_id: person.id,
      participant_type: Person.sti_name
    )
  end

  def flash_message(type, attrs = {})
    attrs[:event] = event.name
    attrs[:event_type] = event.class.label
    I18n.t("event.participation_lists.#{action_name}.#{type}", **attrs)
  end

  def role_type
    event.find_role_type!(params[:role][:type]) if params[:role]
  end

  def group
    @group ||= Group.find(params[:group_id])
  end

  def event
    @event ||= Event.find(params[:event_id])
  end

  def people
    @people ||= all_filtered_or_listed_people
  end
end
