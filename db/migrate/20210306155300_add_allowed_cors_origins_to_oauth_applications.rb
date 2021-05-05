# frozen_string_literal: true

#  Copyright (c) 2021, CVP Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class AddAllowedCorsOriginsToOauthApplications < ActiveRecord::Migration[6.0]
  def change
    add_column :oauth_applications, :allowed_cors_origins, :mediumtext, null: false
  end
end
