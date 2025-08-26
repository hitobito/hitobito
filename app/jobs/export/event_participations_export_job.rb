#  Copyright (c) 2022, Pfadibewegung Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class Export::EventParticipationsExportJob < Export::ExportBaseJob
  self.parameters = PARAMETERS + [:event_id, :group_id]

  def initialize(format, user_id, event_id, group_id, options)
    super(format, user_id, options)
    @event_id = event_id
    @group_id = group_id
  end

  private

  def entries
    Event::ParticipationFilter
      .new(event, user, @options)
      .list_entries
      .select(Event::Participation.column_names)
  end

  def exporter
    if full_export?
      Export::Tabular::People::ParticipationsFull
    elsif household?
      Export::Tabular::People::ParticipationsHouseholds
    elsif table_display?
      Export::Tabular::Event::Participations::TableDisplays
    else
      Export::Tabular::People::ParticipationsAddress
    end
  end

  def data
    return super unless table_display?

    table_display = TableDisplay.for(@user_id, Event::Participation)
    exporter.export(@format, entries, table_display, group)
  end

  def full_export?
    # This condition has to be in the job because it loads all entries
    @options[:details] && ability.can?(:show_details, entries.build)
  end

  def household?
    @options[:household]
  end

  def table_display?
    @options[:selection]
  end

  def group
    @group ||= Group.find(@group_id)
  end

  def event
    @event ||= Event.find(@event_id)
  end
end
