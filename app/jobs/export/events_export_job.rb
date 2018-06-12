# encoding: utf-8

#  Copyright (c) 2017, Pfadibewegung Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class Export::EventsExportJob < Export::ExportBaseJob

  self.parameters = PARAMETERS + [:event_filter]

  def initialize(format, user_id, event_filter)
    super()
    @format = format
    @exporter = Export::Tabular::Events::List
    @user_id = user_id
    @tempfile_name = 'events-export'
    @event_filter = event_filter
  end

  private

  def send_mail(recipient, file, format)
    Export::EventsExportMailer.completed(recipient, file, format).deliver_now
  end

  def entries
    @event_filter.list_entries
  end
end
