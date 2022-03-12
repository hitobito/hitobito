# encoding: utf-8

#  Copyright (c) 2022, Pfadibewegung Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module TwoFactorAuthenticatable

  extend ActiveSupport::Concern

  included do
    enum two_factor_authentication: [:totp]

    serialize :encrypted_two_fa_secret
    attr_encrypted :two_fa_secret
  end

  def second_factor_required?
    two_factor_authentication.present? || two_factor_authentication_enforced?
  end

  def two_factor_authentication_registered?
    encrypted_two_fa_secret.present?
  end

  def two_factor_authentication_enforced?
    roles.any?(&:two_factor_authentication_enforced)
  end
end
