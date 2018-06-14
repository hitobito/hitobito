# encoding: utf-8

#  Copyright (c) 2017, Pfadibewegung Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class Export::EventsExportJob < Export::ExportBaseJob

  self.parameters = PARAMETERS + [:filter]

  def initialize(format, user_id, filter)
    super(format, user_id, {})
    @exporter = Export::Tabular::Events::List
    @tempfile_name = 'events-export'
    @filter = filter
  end

  private

  def send_mail(recipient, file, format)
    Export::EventsExportMailer.completed(recipient, file, format).deliver_now
  end

  def entries
    @filter.list_entries
  end
end
