# frozen_string_literal: true

#  Copyright (c) 2023, Pfadibewegung Schweiz. This file is part of
#  hitobito_cvp and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class SetBlockWarningSentAtForPeople < ActiveRecord::Migration[6.1]
  def up
    Person::BlockService.block_scope&.update_all(inactivity_block_warning_sent_at: Time.zone.now)
  end
end
