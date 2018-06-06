# encoding: utf-8

#  Copyright (c) 2018, Pfadibewegung Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class Export::EventParticipationsExportJob < Export::ExportBaseJob

  self.parameters = PARAMETERS + [:filter]

  def initialize(format, user_id, filter, options)
    super(format, user_id, options)
    @filter = filter
  end

  private

  def entries
    @filter.list_entries
  end

  def exporter
    if full_export?
      Export::Tabular::People::ParticipationsFull
    else
      Export::Tabular::People::ParticipationsAddress
    end
  end

  def full_export?
    # This condition has to be in the job because it loads all entries
    @options[:details] && ability.can?(:show_details, entries.first)
  end

end
