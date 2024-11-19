#  Copyright (c) 2018, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class Event::ParticipationListsController < SimpleCrudController
  skip_authorization_check
  skip_authorize_resource

  respond_to :js, only: :new

  helper_method :group

  def create
    new_participations = build_new_participations
    success = ActiveRecord::Base.transaction do
      raise ActiveRecord::Rollback unless new_participations.select(&:present?).all?(&:save)
      true
    end

    if success
      redirect_to(group_people_path(group),
        notice: flash_message(:success, count: new_participations.count))
    else
      redirect_to(group_people_path(group),
        alert: flash_message(:failure, count: new_participations.count))
    end
  end

  def new
    @people_ids = params[:ids]
    @event_type = params[:type]
    @event_label = params[:label]
    render "new"
  end

  def self.model_class
    Event::Participation
  end

  private

  def build_new_participations
    people.map do |person|
      Event::Participation.find_or_initialize_by(event: event, person_id: person.id).tap do |participation|
        role = role_type.new(participation: participation)
        break nil if cannot?(:create, role)

        participation.roles << role unless participation.roles.map(&:type).include?(role_type.sti_name)
      end
    end
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
    @people ||= Person.where(id: people_ids).distinct
  end

  def people_ids
    list_param(:ids)
  end
end
