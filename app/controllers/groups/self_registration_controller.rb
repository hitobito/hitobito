# frozen_string_literal: true

#  Copyright (c) 2023, Pfadibewegung Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class Groups::SelfRegistrationController < ApplicationController
  skip_authorization_check

  before_action :assert_empty_honeypot, only: [:create]
  before_action :redirect_to_group_if_necessary
  helper_method :entry, :policy_finder

  delegate :self_registration_active?, to: :group

  def new; end

  def create
    return render :new if params[:autosubmit].present?
    return save_and_redirect if entry.valid? && entry.last_step?

    entry.move_on
    render :new
  end

  private

  def save_and_redirect
    save_entry
    redirect_to redirect_path, notice: success_message
  end

  def save_entry
    Person.transaction do
      entry.save!
      enqueue_notification_email
      send_password_reset_email
    end
  end

  def entry
    @entry ||= model_class.new(
      current_ability: current_ability,
      group: group,
      current_step: params[:step],
      person: current_user,
      **model_params.to_unsafe_h
    )
  end

  def model_params
    params[model_identifier] || ActionController::Parameters.new
  end

  def model_identifier
    @model_identifier ||= model_class.model_name.param_key
  end

  def model_class
    @model_class ||= RegistrationWizards.for(group, current_user)
  end

  def authenticate?
    false
  end

  def group
    @group ||= Group.find(params[:group_id])
  end

  def assert_empty_honeypot
    if params.delete(:verification).present?
      redirect_to new_person_session_path
    end
  end

  def role_exists?
    !new_user? &&
      Role.where(
        person: current_user,
        group: group,
        type: group.self_registration_role_type,
        archived_at: nil,
        deleted_at: nil
      ).exists?
  end

  def redirect_to_group_if_necessary
    return redirect_to(group_path(group), t('.disabled')) unless group.self_registration_active?

    redirect_to(group_path(group), t('.role_exists')) if role_exists?
  end

  def redirect_path
    new_user? ? new_person_session_path : group_person_path(current_user.default_group_id, current_user)
  end

  def success_message
    new_user? ? success_message_existing_user : success_message_new_user
  end

  def success_message_new_user
    key = entry.person.email.present? ? :signed_up_but_unconfirmed : :signed_up_but_no_email
    t("devise.registrations.#{key}")
  end

  def success_message_existing_user = t('.role_saved')

  def new_user? = current_user.blank?
end
