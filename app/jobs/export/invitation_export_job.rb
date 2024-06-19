# encoding: utf-8

#  Copyright (c) 2023, Cevi Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class Export::InvitationsExportJob < Export::ExportBaseJob

  self.parameters = PARAMETERS + [:event_id]

  def initialize(user_id, event_id, options)
    super(:csv, user_id, options)
    @exporter = Export::Tabular::Invitations::List
    @event_id = event_id
  end

  private

  def entries
    event.invitations
         .without_deleted
         .order(:lft)
  end

  def group
    @event ||= Event.find(@event_id)
  end
end

