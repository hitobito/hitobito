# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of hitobito and licensed under the
#  Affero General Public License version 3 or later. See the COPYING file at the top-level directory
#  or at https://github.com/hitobito/hitobito.

module Wizards
  class RegisterNewUsersController < BaseController
    skip_authorization_check

    before_action :assert_empty_honeypot
    before_action :redirect_to_group_if_necessary

    helper_method :group, :policy_finder

    private

    def save_wizard
      super.tap do
        enqueue_duplicate_locator_job
        enqueue_notification_email
        send_password_reset_email
      end
    end

    def enqueue_duplicate_locator_job
      Person::DuplicateLocatorJob.new(wizard.person.id).enqueue!
    end

    def enqueue_notification_email
      return if group.self_registration_notification_email.blank?

      Groups::SelfRegistrationNotificationMailer
        .self_registration_notification(group.self_registration_notification_email, wizard.role)
        .deliver_later
    end

    def send_password_reset_email
      return if wizard.person.email.blank?

      Person.send_reset_password_instructions(email: wizard.person.email)
    end

    def notification_email
      group.self_registration_notification_email
    end

    def model_class
      Wizards::RegisterNewUserWizard
    end

    def authenticate?
      false
    end

    def redirect_to_group_if_necessary
      return redirect_to group_path(group) unless group.self_registration_active?

      redirect_to group_self_inscription_path(group) if signed_in?
    end

    def wizard
      @wizard ||= model_class.new(
        group: group,
        current_step: params[:step].to_i,
        **model_params.to_unsafe_h
      )
    end

    def group
      @group ||= Group.find(params[:group_id])
    end

    def redirect_target
      new_person_session_path
    end

    def success_message
      key = wizard.person.email.present? ? :signed_up_but_unconfirmed : :signed_up_but_no_email
      I18n.t("devise.registrations.#{key}")
    end

    def assert_empty_honeypot
      if params.delete(:verification).present?
        redirect_to new_person_session_path
      end
    end

    def policy_finder
      @policy_finder ||= Group::PrivacyPolicyFinder.for(group: group, person: wizard.person)
    end
  end
end
