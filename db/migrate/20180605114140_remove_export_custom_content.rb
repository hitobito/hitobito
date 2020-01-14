# encoding: utf-8

#  Copyright (c) 2012-2018, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class RemoveExportCustomContent < ActiveRecord::Migration[4.2]

  CONTENTS_TO_REMOVE = %w(content_subscriptions_export
                          content_events_export
                          content_event_participations_export
                          content_people_export)

  def up
    say_with_time "Removing obsolete CustomContents" do
      CONTENTS_TO_REMOVE.each do |key|
        custom_content = CustomContent.find_by(key: key)
        next unless custom_content
        say custom_content.label, :subitem
        custom_content.destroy!
      end
    end
  end

  def down; end
end
