# frozen_string_literal: true

#  Copyright (c) 2012-2026, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class AddDescriptionToOauthApplications < ActiveRecord::Migration[6.1]
  def change
    add_column :oauth_applications, :description, :text
  end
end
