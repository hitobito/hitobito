# encoding: utf-8

#  Copyright (c) 2012-2018, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class RemoveExportCustomContent < ActiveRecord::Migration

  CONTENTS_TO_REMOVE = %w(content_subscriptions_export
                          content_events_export
                          content_event_participations_export
                          content_people_export)
  
  def down
    CONTENTS_TO_REMOVE.each do |key|
      custom_content = CustomContent.find_by(key: key)
      return unless custom_content
      CustomContent::Translation.where(custom_content_id: custom_content.id)
      custom_content.destroy
    end
  end

  def up; end
end
