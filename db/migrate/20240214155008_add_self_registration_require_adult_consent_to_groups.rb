# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito

class AddSelfRegistrationRequireAdultConsentToGroups < ActiveRecord::Migration[6.1]
  def change
    change_table(:groups) do |t|
      t.boolean :self_registration_require_adult_consent, default: false, null: false
    end
  end
end
