# frozen_string_literal: true

#  Copyright (c) 2021, Efficiency-Club Bern. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class Groups::SelfRegistrationController < CrudController
  skip_authorization_check
  skip_authorize_resource

  after_create :success_but_no_email, unless: :email_present?
  after_create :send_password_reset_email, if: :email_present?

  before_action :assert_empty_honeypot, only: [:create]

  before_action :redirect_to_group, unless: :self_registration_active?
  before_action :redirect_to_group, if: :signed_in?

  after_create :send_notification_email

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
    entry.person.save && entry.save
  end

  def return_path
    super.presence || new_person_session_path if valid?
  end

  def success_but_no_email
    flash[:notice] = I18n.t('devise.registrations.signed_up_but_no_email')
  end

  def send_password_reset_email
    Person.send_reset_password_instructions(email: entry.person.email)
    flash[:notice] = I18n.t('devise.registrations.signed_up_but_unconfirmed')
  end

  def assert_empty_honeypot
    if params.delete(:verification).present?
      redirect_to new_person_session_path
    end
  end

  def redirect_to_group
    redirect_to group_path(group)
  end

  def signed_in?
    current_user.present?
  end

  def valid?
    entry.valid? && entry.person.valid?
  end

  def email_present?
    entry.person.email.present?
  end

  def person_attrs
    model_params&.delete(:new_person)
      &.permit(*PeopleController.permitted_attrs)
      &.merge(primary_group_id: group.id)
  end

  def group
    @group ||= Group.find(params[:group_id])
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
