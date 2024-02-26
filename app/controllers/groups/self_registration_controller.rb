# frozen_string_literal: true

#  Copyright (c) 2021, Efficiency-Club Bern. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class Groups::SelfRegistrationController < ApplicationController
  skip_authorization_check

  before_action :assert_empty_honeypot, only: [:create]
  before_action :redirect_to_group_if_necessary
  helper_method :entry, :policy_finder

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
    redirect_to new_person_session_path, notice: success_message
  end

  def save_entry
    Person.transaction do
      entry.save!
      enqueue_notification_email
      send_password_reset_email
    end
  end

  def entry
    @entry ||= SelfRegistration.new(
      group: group,
      params: params.to_unsafe_h.deep_symbolize_keys
    )
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

  def redirect_to_group_if_necessary
    return redirect_to group_path(group) unless group.self_registration_active?

    redirect_to group_self_inscription_path(group) if signed_in?
  end

  def enqueue_notification_email
    return if group.self_registration_notification_email.blank?

    ::Groups::SelfRegistrationNotificationMailer
      .self_registration_notification(group.self_registration_notification_email,
                                      entry.main_person.role).deliver_later
  end

  def send_password_reset_email
    return if entry.main_person.email.blank?

    Person.send_reset_password_instructions(email: entry.main_person.email)
  end

  def success_message
    key = entry.main_person.email.present? ? :signed_up_but_unconfirmed : :signed_up_but_no_email
    I18n.t("devise.registrations.#{key}")
  end

  def policy_finder
    @policy_finder ||= Group::PrivacyPolicyFinder.for(group: group, person: entry.main_person)
  end
end
