# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module People::MembershipVerification
  extend ActiveSupport::Concern

  included do
    validates :membership_verify_token, uniqueness: { allow_blank: true }
  end

  def membership_verify_token
    token = super

    if token.nil?
      token = SecureRandom.base58(24)
      update!(membership_verify_token: token)
    end

    token
  end
end
