#  frozen_string_literal: true

#  Copyright (c) 2021, Efficiency-Club Bern. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class AddSelfRegistrationRoleTypeToGroups < ActiveRecord::Migration[6.1]
  def change
    add_column :groups, :self_registration_role_type, :string, default: nil, null: true
  end
end
