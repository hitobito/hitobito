#  Copyright (c) 2023, Cevi Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class Export::InvitationsExportJob < Export::ExportBaseJob
  self.parameters = PARAMETERS + [:event_id]

  def initialize(format, user_id, event_id, options)
    super(format, user_id, options)
    @event_id = event_id
    @exporter = Export::Tabular::Invitations::List
  end

  private

  def entries
    event.invitations
  end

  def event
    @event ||= Event.find(@event_id)
  end
end
