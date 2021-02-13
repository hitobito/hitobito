# encoding: utf-8

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
    ActiveRecord::Base.transaction do
      new_participations.map(&:save).all?(&:present?)
    end

    redirect_to(group_people_path(group),
                notice: flash_message(:success, count: new_participations.count))
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
      participation = event.participations.new
      participation.person_id = person.id
      role = role_type.new(participation: participation)
      authorize!(:create, role)
    end
  end

  def flash_message(type, attrs = {})
    attrs[:event] = event.name
    attrs[:event_type] = event.class.label
    I18n.t("event.participation_lists.#{action_name}.#{type}", attrs)
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
