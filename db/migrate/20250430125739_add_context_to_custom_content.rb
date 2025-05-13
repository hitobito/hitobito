# frozen_string_literal: true

#  Copyright (c) 2025, Die Mitte Schweiz. This file is part of
#  hitobito_cvp and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_die_mitte.

class AddContextToCustomContent < ActiveRecord::Migration[7.1]
  def change
    add_reference :custom_contents, :context, polymorphic: true
    CustomContent.reset_column_information
  end
end
