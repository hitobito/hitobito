# frozen_string_literal: true

#  Copyright (c) 2026, Schweizer Alpen-Club. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class AddPreselectRememberMeToOauthApplications < ActiveRecord::Migration[8.1]
  def change
    add_column :oauth_applications, :preselect_remember_me, :boolean, default: false, null: false
  end
end
