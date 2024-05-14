# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module People::MembershipVerification
  extend ActiveSupport::Concern

  def membership_verify_token
    (new_record? || super.present?) ? super : init_membership_verify_token
  end

  # token should not be set manually
  def membership_verify_token=(_value); end

  private

  def init_membership_verify_token
    token = SecureRandom.base58(24)
    while Person.where(membership_verify_token: token).exists?
      raise 'token must be unique'
    end
    update_column(:membership_verify_token, token)
    token
  end

end
