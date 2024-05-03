# frozen_string_literal: true

#  Copyright (c) 2012-2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

class AddVisibilityToEventAttachments < ActiveRecord::Migration[6.1]
  def up
    add_column :event_attachments, :visibility, :string, default: nil

    Event::Attachment.update_all(visibility: 'global')
  end

  def down
    remove_column :event_attachments, :visibility
  end
end
