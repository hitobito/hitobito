# encoding: utf-8

#  Copyright (c) 2022, Pfadibewegung Schweiz. This file is part of
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
    elsif household?
      Export::Tabular::People::ParticipationsHouseholds
    elsif table_display?
      Export::Tabular::People::TableDisplays
    else
      Export::Tabular::People::ParticipationsAddress
    end
  end

  def data
    return super unless table_display?

    table_display = TableDisplay.for(@user_id, Event::Participation)
    Export::Tabular::People::TableDisplays.export(@format, entries, table_display)
  end

  def full_export?
    # This condition has to be in the job because it loads all entries
    @options[:details] && ability.can?(:show_details, entries.first)
  end

  def household?
    @options[:household]
  end

  def table_display?
    @options[:selection]
  end
end
