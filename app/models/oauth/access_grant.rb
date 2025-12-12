# frozen_string_literal: true

# Copyright (c) 2021, CVP Schweiz. This file is part of
# hitobito and licensed under the Affero General Public License version 3
# or later. See the COPYING file at the top-level directory or at
# https://github.com/hitobito/hitobito.
module Oauth
  class AccessGrant < Doorkeeper::AccessGrant
    belongs_to :person, foreign_key: :resource_owner_id, inverse_of: :access_grants

    scope :list, -> { order(created_at: :desc) }
    scope :for, ->(uri) { where(redirect_uri: uri) }
    scope :not_expired, -> { where("created_at + interval '1 second' * expires_in > now()") }

    def self.active
      not_expired.where(revoked_at: nil)
    end

    def to_s
      token
    end
  end
end
