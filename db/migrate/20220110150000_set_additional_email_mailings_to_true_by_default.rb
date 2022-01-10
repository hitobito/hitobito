#  frozen_string_literal: true

#  Copyright (c) 2021, Pfadibewegung Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class SetAdditionalEmailMailingsToTrueByDefault < ActiveRecord::Migration[6.1]
  def change
    change_column_default :additional_emails, :mailings, true
  end
end
