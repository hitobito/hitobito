# frozen_string_literal: true

# Copyright (c) 2021, hitobito AG. This file is part of
# hitobito and licensed under the Affero General Public License version 3
# or later. See the COPYING file at the top-level directory or at
# https ://github.com/hitobito/hitobito.

module TwoFactor
  extend ActiveSupport::Concern

  included do
    helper_method :pending_two_factor_person
  end

  private

  def two_factor_authentication_pending?
    session[:pending_two_factor_person_id].present?
  end

  def reset_two_factor_authentication
    session.delete(:pending_two_factor_person_id)
  end

  def pending_two_factor_person
    return unless two_factor_authentication_pending?

    Person.find(session[:pending_two_factor_person_id])
  end

  def init_two_factor_auth(resource, after_2fa_path)
    # Two sign_out statements are required for live deployments for some reason.
    # Locally it works with just one sign_out
    sign_out(resource) && sign_out

    session[:remember_me] = true?(resource_params[:remember_me])
    session[:pending_two_factor_person_id] = resource.id
    session[:after_2fa_path] = after_2fa_path

    redirect_to_two_factor_authentication
  end

  def redirect_to_two_factor_authentication
    redirect_to two_factor_auth_path, notice: ''
  end

  def two_factor_auth_path
    factor = 'totp' if pending_two_factor_person.two_factor_authentication_enforced?
    factor ||= pending_two_factor_person.two_factor_authentication

    session[:pending_second_factor_authentication] = factor

    new_users_second_factor_path
  end

  def remember_me?
    session[:remember_me]
  end
end
