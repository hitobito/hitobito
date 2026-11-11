# frozen_string_literal: true

#  Copyright (c) 2026, Schweizer Alpen-Club. This file is part of hitobito and licensed under the
#  Affero General Public License version 3 or later. See the COPYING file at the top-level directory
#  or at https://github.com/hitobito/hitobito.

class AddRefreshTokenLifetimeDaysToOauthApplications < ActiveRecord::Migration[8.0]
  def change
    add_column :oauth_applications, :refresh_token_lifetime_days, :integer
  end
end
