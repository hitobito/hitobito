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

  def pending_two_factor_person
    return unless two_factor_authentication_pending?

    Person.find(session[:pending_two_factor_person_id])
  end

  def two_factor_auth_path
    factor = :totp if pending_two_factor_person.totp_forced?
    factor ||= pending_two_factor_person.second_factor_auth.to_sym

    session[:pending_second_factor_authentication] = factor

    new_users_second_factor_path
  end
end
