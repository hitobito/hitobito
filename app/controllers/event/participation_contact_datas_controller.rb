#  Copyright (c) 2012-2017, Pfadibewegung Schweiz. This file is part of
#  hitobito_pbs and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_pbs.

class Event::ParticipationContactDatasController < ApplicationController
  include PrivacyPolicyAcceptable

  helper_method :group, :event, :entry

  authorize_resource :entry, class: Event::ParticipationContactData

  decorates :group, :event

  before_action :set_entry, :group, :policy_finder

  def edit
  end

  def update
    if entry.valid? && privacy_policy_accepted? && entry.save
      set_privacy_policy_acceptance if privacy_policy_needed_and_accepted?

      redirect_to after_update_success_path
    else
      add_privacy_policy_not_accepted_error(entry)
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def after_update_success_path
    new_group_event_participation_path(
      group,
      event,
      {event_role: {type: params[:event_role][:type]},
       event_participation: {person_id: entry.person.id}}
    )
  end

  def entry
    @participation_contact_data
  end

  def build_entry
    contact_data_class.new(event, person)
  end

  def set_entry
    @participation_contact_data =
      if params[model_identifier]
        contact_data_class.new(event, person, model_params)
      else
        build_entry
      end
  end

  def model_identifier
    contact_data_class.to_s.underscore.tr("/", "_")
  end

  def contact_data_class
    return Event::ParticipationContactDatas::Managed if participation_for_managed?

    Event::ParticipationContactData
  end

  def event
    @event ||= Event.find(params[:event_id])
  end

  def group
    @group ||= Group.find(params[:group_id])
  end

  def model_params
    params.require(model_identifier).permit(permitted_attrs)
  end

  def permitted_attrs
    PeopleController.permitted_attrs + [:privacy_policy_accepted]
  end

  def person
    @person ||= entry&.person || params_person || current_user
  end

  def params_person
    current_user.manageds.find(params[:person_id]) if params[:person_id].present?
  end

  def privacy_policy_param
    params.dig(contact_data_param_key, :privacy_policy_accepted)
  end

  def participation_for_managed?
    current_user.manageds.include?(params_person)
  end

  def contact_data_param_key
    if participation_for_managed?
      :event_participation_contact_datas_managed
    else
      :event_participation_contact_data
    end
  end
end
