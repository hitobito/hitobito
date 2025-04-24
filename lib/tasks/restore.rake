# frozen_string_literal: true

#  Copyright (c) 2024-2024, Puzzle ITC. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class BackupRestorer
  def initialize(args)
    @args = args
    @result = []
    @mode = :sql
  end

  def result
    puts @result

    case @mode
    when :sql then warn "#{@result.size} INSERTS generated."
    when :ruby then warn "Script generated."
    end
  end

  def load_event
    event_id = @args.fetch(:id) { abort("You need to pass an Event-ID to restore") }
    @event = Event.find(event_id)
    warn "Found Event##{event_id} '#{@event}'"
  end

  def dump_event
    @result << dump(@event)
  end

  def dump_participations
    switch_mode(:sql)

    @event.participations.each do |participation|
      @result << dump(participation)
      @result << dump(participation.application) if participation.application.present?
      participation.roles.each { @result << dump(_1) }
    end
  end

  def script_header
    switch_mode(:ruby)

    @result << <<~RUBY
      #!/usr/bin/env ruby

      connection = ActiveRecord::Base.connection

    RUBY
  end

  def script_participations_and_answers
    switch_mode(:ruby)
    # # the current data-restore does not touch applications, so this is left out for now
    # appl_id = if #{participation.application.present?.inspect} == 'true'
    #             connection.select_value("#{dump(participation.application, except: %w(id), sql_suffix: 'RETURNING id')}")
    #           end

    @event.participations.each do |participation|
      @result << <<~RUBY
        if Event::Participation.where(event_id: @event.id, person_id: participation.person_id).exists?
          puts 'Skipping existing Participation #{participation.id} for Person #{participation.person_id}'
        else
          puts 'Restoring Participation #{participation.id} for Person #{participation.person_id}'

          part_id = connection.select_value("#{dump(participation, except: %w(id), sql_suffix: 'RETURNING id')}")

          role_sqls = "#{participation.roles.map { |event_role| dump(event_role, except: %w(id participation_id), overrides: { participation_id: 'PARTICIPATION_ID'}) }.join}".split(';')
          role_sqls.each do |role_sql|
            connection.execute(role_sql.replace('PARTICIPATION_ID', part_id))
          end

          answer_sqls = "#{participation.answers.map { |answer| dump(answer, except: %w(id participation_id), overrides: { participation_id: 'PARTICIPATION_ID'}) }.join}".split(';')
          answer_sqls.each do |answer_sql|
            connection.execute(answer_sql.replace('PARTICIPATION_ID', part_id))
          end
        end

      RUBY
    end
  end

  def dump_answers
    @event.questions.each do |question|
      question.answers.each { @result << dump(_1) }
    end
  end

  # def dump_event_groups
  #   @event.groups.map(&:id).each do |group_id|
  #     @result << sql('events_groups', %w(event_id group_id), [@event.id, group_id])
  #   end
  # end

  private

  def switch_mode(mode)
    if @result.present? && mode != @mode
      raise "Switching the mode after setting and using it is not supported."
    end

    @mode = mode
  end

  def dump(object, except: %w(search_column), overrides: {}, sql_suffix: "")
    table = object.class.table_name
    db_columns = object.class.column_names
    attrs = object.attributes_before_type_cast.slice(*db_columns).except(*except)

    columns = attrs.keys
    values = attrs.values.map do |val|
      case val
      when NilClass then "NULL"
      when String, Time then "'#{val.inspect.delete_prefix('"').delete_suffix('"')}'"
      else val
      end
    end

    overrides.each do |key, value|
      columns << key.to_s
      values << value.to_s
    end

    sql(table, columns, values, sql_suffix)
  end

  def only_missing(&block)
    previous_suffix, @default_suffix = @default_suffix, 'ON CONFLICT DO NOTHING'
    block.call
  ensure
    @default_suffix = previous_suffix
  end

  def sql(table, columns, values, sql_suffix = @default_suffix)
    <<~SQL.squish
      INSERT INTO #{table}
        (#{columns.join(", ")})
      VALUES
        (#{values.join(", ")})
      #{sql_suffix};
    SQL
  end
end

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
        sql_result << dumper[participation.application] if participation.application.present?
        participation.roles.each { sql_result << dumper[_1] }
      end

      # TODO: export subscriptions and their relations
      # TODO: export person_add_requests and their relations

      puts sql_result
      warn "#{sql_result.size} INSERTS generated."
    end

    desc "Export Participations of an Event with all associated things"
    task :participations, [:id] => [:environment] do |_task, args|
      dumper = BackupRestorer.new(args)
      dumper.load_event

      dumper.dump_participations
      dumper.dump_answers

      dumper.result
    end
  end

  namespace :script do
    task :participations, [:id] => [:environment] do |_task, args|
      dumper = BackupRestorer.new(args)
      dumper.load_event

      dumper.script_header
      dumper.script_participations_and_answers

      dumper.result
    end
  end
end
