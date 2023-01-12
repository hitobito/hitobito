# frozen_string_literal: true

#  Copyright (c) 2021, Efficiency-Club Bern. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class Groups::SelfRegistrationController < CrudController
  skip_authorization_check
  skip_authorize_resource

  after_create :send_notification_email, if: :valid?
  after_save :set_success_notice, if: :valid?
  after_create :set_failure_notice, unless: :valid?

  before_action :assert_empty_honeypot, only: [:create]

  before_action :redirect_to_group_if_necessary
  prepend_before_action :policy_finder

  delegate :self_registration_active?, to: :group

  private

  def send_notification_email
    return if group.self_registration_notification_email.blank?

    Groups::SelfRegistrationNotificationMailer
      .self_registration_notification(group.self_registration_notification_email,
                                      entry).deliver_now
  end

  def build_entry
    role = super
    role.group = group
    role.type = group.self_registration_role_type
    role.person = Person.new(person_attrs)
    role
  end

  def save_entry
    unless privacy_policy_accepted?
      set_failure_notice
      return false
    end

    ActiveRecord::Base.transaction do
      entry.save if entry.person.save
    end
  end

  def return_path
    if valid?
      super.presence || new_person_session_path
    else
      group_self_registration_path(group)
    end
  end

  def set_success_notice
    if entry.person.email.present?
      Person.send_reset_password_instructions(email: entry.person.email)
      flash[:notice] = I18n.t('devise.registrations.signed_up_but_unconfirmed')
    else
      flash[:notice] = I18n.t('devise.registrations.signed_up_but_no_email')
    end
  end

  def error_messages
    errors = []
    errors += entry.person.errors.full_messages
    errors << t('.flash.privacy_policy_not_accepted') unless privacy_policy_accepted?
    @@helper.safe_join(errors, '<br/>'.html_safe)
  end

  def assert_empty_honeypot
    if params.delete(:verification).present?
      redirect_to new_person_session_path
    end
  end

  def redirect_to_group_if_necessary
    return redirect_to group_path(group) unless self_registration_active?
    redirect_to group_path(group) if signed_in?
  end

  def signed_in?
    current_user.present?
  end

  def valid?
     privacy_policy_accepted? && entry.valid? && entry.person.valid?
  end

  def privacy_policy_accepted?
    return true unless @policy_finder.acceptance_needed?

    true?(privacy_policy_param)
  end

  def person_attrs
    model_params&.require(:new_person)
      &.permit(*PeopleController.permitted_attrs, :privacy_policy_accepted)
      &.merge(primary_group_id: group.id)
  end

  def privacy_policy_param
    model_params&.require(:new_person)[:privacy_policy_accepted]
  end


  def group
    @group ||= Group.find(params[:group_id])
  end

  def policy_finder
    @policy_finder ||= Group::PrivacyPolicyFinder.for(group: group, person: entry.person)
  end

  def authenticate?
    false
  end

  def path_args(entry)
    [group, entry]
  end

  def self.model_class
    @model_class ||= Role
  end
end
