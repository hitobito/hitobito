# frozen_string_literal: true

#  Copyright (c) 2012-2022, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module Person::DeviseOverrides
  extend ActiveSupport::Concern

  class_methods do
    # Allow login with all attrs defined in `devise_login_id_attrs`
    def find_for_database_authentication(warden_conditions)
      if login = warden_conditions[:login_identity]
        Array.wrap(devise_login_id_attrs).map do |attr|
          where(attr => login)
        end.reduce(:or).first
      end
    end
  end

  # from lib/devise/models/recoverable.rb
  def send_reset_password_instructions
    persisted? && super
  end

  def confirmation_required?
    password? && super
  end

  def reconfirmation_required?
    password? && super
  end

  def postpone_email_change?
    password? && super
  end

  def postpone_email_change_until_confirmation_and_regenerate_confirmation_token
    super
    @show_email_change_info = true
  end

  def show_email_change_info?
    @show_email_change_info.present?
  end

  def clear_reset_password_token!
    clear_reset_password_token
    save(validate: false)
  end

  def generate_reset_password_token!
    set_reset_password_token.tap { save!(validate: false) }
  end

  def set_reset_password_token
    self.reset_password_sent_to = email
    super
  end

  def generate_authentication_token!
    token = generate_authentication_token
    save!(validate: false)
    token
  end

  def generate_authentication_token
    loop do
      token = Devise.friendly_token
      unless self.class.exists?(authentication_token: token)
        self.authentication_token = token
        break token
      end
    end
  end

  # Owner: Devise::Models::DatabaseAuthenticatable
  # We override this to allow users updating passwords when no password has been set
  def update_with_password(params, *options)
    current_password = params.delete(:current_password)

    if params[:password].blank?
      params.delete(:password)
      params.delete(:password_confirmation) if params[:password_confirmation].blank?
    end

    result = update_password_if_valid(params, current_password, *options)
    clean_up_passwords
    result
  end

  private

  def email_required?
    false
  end

  # Checks whether a password is needed or not. For validations only.
  # Passwords are required if the password or confirmation are being set somewhere.
  def password_required?
    password || password_confirmation
  end

  def update_password_if_valid(params, current_password, *options)
    if encrypted_password.nil? || valid_password?(current_password)
      update(params, *options)
    else
      assign_attributes(params, *options)
      valid?
      errors.add(:current_password, current_password.blank? ? :blank : :invalid)
      false
    end
  end
end
