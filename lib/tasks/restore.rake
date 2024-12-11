# frozen_string_literal: true

#  Copyright (c) 2024-2024, Puzzle ITC. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

namespace :restore do
  namespace :export do
    # TODO: Extract the dumper and other helpers into a dedicated exporter-class that
    desc "Export an Event with all associated things"
    task :event, [:id] => [:environment] do |_task, args|
      event_id = args.fetch(:id) { abort("You need to pass an Event-ID to restore") }
      event = Event.find(event_id)

      sql_result = []
      warn "Found Event##{event_id} '#{event}'"

      dumper = ->(object) do
        table = object.class.table_name
        db_columns = object.class.column_names
        attrs = object.attributes_before_type_cast.slice(*db_columns).except("search_column")

        columns = attrs.keys
        values = attrs.values.map do |val|
          case val
          when NilClass then "NULL"
          when String, Time then "'#{val.inspect.delete_prefix('"').delete_suffix('"')}'"
          else val
          end
        end

        <<~SQL.squish
          INSERT INTO #{table}
          (#{columns.join(", ")})
          VALUES
          (#{values.join(", ")});
        SQL
      end

      sql_result << dumper[event]

      event.groups.map(&:id).each do |group_id|
        # TODO: extract into proc or so if this happens more often
        sql_result << <<~SQL.squish
          INSERT INTO events_groups
          (event_id, group_id)
          VALUES
          (#{event.id}, #{group_id});
        SQL
      end

      %i[translations dates invitations tags].each do |assoc|
        event.send(assoc).each { sql_result << dumper[_1] }
      end

      event.questions.each do |question|
        sql_result << dumper[question]
        question.translations.each { sql_result << dumper[_1] }
        question.answers.each { sql_result << dumper[_1] }
      end

      event.participations.each do |participation|
        sql_result << dumper[participation]
        sql_result << dumper[participation.application]
        participation.roles.each { sql_result << dumper[_1] }
      end

      # TODO: export subscriptions and their relations
      # TODO: export person_add_requests and their relations

      puts sql_result
      warn "#{sql_result.size} INSERTS generated."
    end
  end
end
