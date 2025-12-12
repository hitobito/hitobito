#  Copyright (c) 2019-2024, Pfadibewegung Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.
module Oauth
  class AccessToken < Doorkeeper::AccessToken
    belongs_to :person, foreign_key: :resource_owner_id, inverse_of: :access_tokens
    belongs_to :application, class_name: "Oauth::Application"

    scope :list, -> { order(created_at: :desc) }
    # no need to check expires_in as refresh_token would never expire
    scope :active, -> { where(revoked_at: nil) }

    devise

    def to_s
      token
    end
  end
end
