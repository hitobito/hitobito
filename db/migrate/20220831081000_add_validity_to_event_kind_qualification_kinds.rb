# frozen_string_literal: true

#  Copyright (c) 2022, Jungwacht Blauring. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class AddValidityToEventKindQualificationKinds < ActiveRecord::Migration[6.1]
  def change
    add_column :event_kind_qualification_kinds, :validity, :string, default: :valid_or_expired, null: false
  end
end
