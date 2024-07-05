# frozen_string_literal: true

#  Copyright (c) 2022, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class Devise::Hitobito::PasswordsController < Devise::PasswordsController
  skip_before_action :reject_blocked_person!

  def successfully_sent?(resource)
    if resource.login?
      super
    else
      flash[:alert] = I18n.translate("devise.failure.signin_not_allowed")
    end
  end

  def create
    previous_locale = I18n.locale
    resource = resource_class.find_by(email: resource_params["email"])
    I18n.locale = resource&.language || previous_locale

    # The block gets executed after sending the mail and before redirecting
    super do
      I18n.locale = previous_locale
    end
  end

  def update
    super do |resource|
      if should_confirm_email?(resource)
        resource.reset_password_sent_to = nil
        resource.confirm
      end
    end
  end

  private

  def should_confirm_email?(resource)
    return false if resource.errors.present?
    return false if resource.confirmed? && !resource.pending_reconfirmation?

    confirmable_email = resource.pending_reconfirmation? ?
                            resource.unconfirmed_email : resource.email

    return false if confirmable_email.blank? || resource.reset_password_sent_to.blank?

    # We may only confirm the email address which the reset password email was sent to.
    # If the email has been changed since sending the password reset email,
    # this would be an attack vector: An attacker could...
    # 1. request a password reset email to their owned address, but not click it yet
    # 2. change their email or have it changed to some address they don't own and can't confirm
    # 3. click the password reset link -> their new email address would mistakenly get confirmed
    return false if resource.reset_password_sent_to != confirmable_email

    true
  end
end
