# frozen_string_literal: true

#  Copyright (c) 2025, Schweizer Alpen-Club. This file is part of hitobito and licensed under the
#  Affero General Public License version 3 or later. See the COPYING file at the top-level directory
#  or at https://github.com/hitobito/hitobito.

module Oauth
  class AccessTokenCleanupJob < RecurringJob
    run_every 12.hours

    private

    def perform_internal
      non_refreshable_access_tokens.delete_all
      old_revoked_access_tokens.delete_all
    end

    def old_revoked_access_tokens
      Oauth::AccessToken.where(revoked_at: [..3.days.ago])
    end

    def non_refreshable_access_tokens
      refresh_token_expires_in = Settings.oidc.refresh_token_expires_in.seconds.ago
      Oauth::AccessToken.where(created_at: [..refresh_token_expires_in])
    end
  end
end
