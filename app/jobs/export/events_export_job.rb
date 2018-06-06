# encoding: utf-8

#  Copyright (c) 2017, Pfadibewegung Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class Export::EventsExportJob < Export::ExportBaseJob

  self.parameters = PARAMETERS + [:filter]

  def initialize(format, user_id, filter, options)
    super(format, user_id, options)
    @exporter = Export::Tabular::Events::List
    @filter = filter
  end

  private

  def entries
    @filter.list_entries
  end
end
