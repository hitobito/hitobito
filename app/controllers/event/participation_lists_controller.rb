#  Copyright (c) 2018, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class Event::ParticipationListsController < SimpleCrudController
  include FilteredPeople # provides all_filtered_or_listed_people, person_filter and list_filter_args

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
    people.map do |person|
      Event::Participation.find_or_initialize_by(event: event, participant_id: person.id,
        participant_type: Person.sti_name).tap do |participation|
        role = role_type.new(participation: participation)
        break nil if cannot?(:create, role)

        # rubocop:todo Layout/LineLength
        participation.roles << role unless participation.roles.map(&:type).include?(role_type.sti_name)
        # rubocop:enable Layout/LineLength
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
    @people ||= all_filtered_or_listed_people
  end
end
