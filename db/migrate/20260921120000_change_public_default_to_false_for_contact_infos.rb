#  frozen_string_literal: true

#  Copyright (c) 2026, Hitobito AG. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class ChangePublicDefaultToFalseForContactInfos < ActiveRecord::Migration[6.1]
  def change
    change_column_default :phone_numbers, :public, from: true, to: false
    change_column_default :additional_emails, :public, from: true, to: false
    change_column_default :social_accounts, :public, from: true, to: false
  end
end
