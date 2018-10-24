# encoding: utf-8

#  Copyright (c) 2018, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class Event::ParticipationListsController < SimpleCrudController

  self.nesting = Group, Event

  skip_authorization_check
  skip_authorize_resource

  def create
    new_participations = build_new_participations
    ActiveRecord::Base.transaction do
      new_participations.map(&:save).all?(&:present?)
    end

    redirect_to(group_people_path(group),
                notice: flash_message(:success, count: new_participations.count))
  end

  def self.model_class
    Event::Participation
  end

  private

  def build_new_participations
    people.map do |person|
      participation = parent.participations.new
      participation.person_id = person.id
      role = role_type.new(participation: participation)
      authorize!(:create, role)
    end
  end

  def flash_message(type, attrs = {})
    attrs[:event] = parent.name
    attrs[:event_type] = parent.class.label
    I18n.t("event.participation_lists.#{action_name}.#{type}", attrs)
  end

  def role_type
    parent.find_role_type!(params[:role][:type]) if params[:role]
  end

  def group
    @group ||= Group.find(params[:group_id])
  end

  def people
    @people ||= group.people.where(id: people_ids).uniq
  end

  def people_ids
    params[:ids].to_s.split(',')
  end
end
