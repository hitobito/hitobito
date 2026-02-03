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
    event_id = @args.fetch(:event_id) { abort("You need to pass an Event-ID to restore") }
    @event = Event.find(event_id)
    warn "Found Event##{event_id} '#{@event}'"
  end

  def load_group
    group_id = @args.fetch(:group_id) { abort("You need to pass a Group-ID to restore") }
    @group = Group.find(group_id)
    warn "Found Group##{group_id} '#{@group}'"
  end

  def dump_event
    switch_mode(:sql)

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

  def dump_answers
    switch_mode(:sql)

    @event.questions.each do |question|
      question.answers.each { @result << dump(_1) }
    end
  end

  # def dump_event_groups
  #   @event.groups.map(&:id).each do |group_id|
  #     @result << sql('events_groups', %w(event_id group_id), [@event.id, group_id])
  #   end
  # end

  # rubocop:todo Metrics/MethodLength
  def dump_invoices # rubocop:todo Metrics/AbcSize # rubocop:todo Metrics/MethodLength
    switch_mode(:sql)

    only_missing do
      @group.issued_invoices.each do |invoice|
        @result << dump(invoice)

        invoice.invoice_items.each do |invoice_item|
          @result << dump(invoice_item)
        end

        invoice.payments.each do |payment|
          @result << dump(payment)
          @result << dump(payment.payee) if payment.payee
        end

        invoice.payment_reminders.each do |payment_reminder|
          @result << dump(payment_reminder)
        end
      end
    end
  end
  # rubocop:enable Metrics/MethodLength

  def script_header
    switch_mode(:ruby)

    @result << <<~RUBY
      #!/usr/bin/env ruby

      connection = ActiveRecord::Base.connection

    RUBY
  end

  def script_participations_and_answers # rubocop:todo Metrics/MethodLength
    switch_mode(:ruby)
    # # the current data-restore does not touch applications, so this is left out for now
    # appl_id = if #{participation.application.present?.inspect} == 'true'
    # rubocop:todo Layout/LineLength
    #             connection.select_value("#{dump(participation.application, except: %w(id), sql_suffix: 'RETURNING id')}")
    # rubocop:enable Layout/LineLength
    #           end

    @event.participations.each do |participation|
      @result << <<~RUBY
        if Event::Participation.where(event_id: #{@event.id}, person_id: #{participation.person_id}).exists?
          puts 'Skipping existing Participation #{participation.id} for Person #{participation.person_id}'
        else
          puts 'Restoring Participation #{participation.id} for Person #{participation.person_id}'

          part_id = connection.select_value("#{dump(participation, except: %w[id], sql_suffix: "RETURNING id")}")
          raise if part_id.nil?

          "#{participation.roles.map { |event_role| dump(event_role, except: %w[id participation_id], overrides: {participation_id: '#{part_id}'}) }.join}"
            .split(';')
            .each { |sql| connection.execute(sql) }

          "#{participation.answers.map { |answer| dump(answer, except: %w[id participation_id], overrides: {participation_id: '#{part_id}'}) }.join}"
            .split(';')
            .each { |sql| connection.execute(sql) }
        end

      RUBY
    end
  end

  # rubocop:todo Metrics/MethodLength
  def script_invoices # rubocop:todo Metrics/AbcSize # rubocop:todo Metrics/MethodLength
    switch_mode(:ruby)

    @group.issued_invoices.each do |invoice|
      @result << <<~RUBY
        inv_id = if Invoice.where(sequence_number: '#{invoice.sequence_number}').exists?
                   puts 'Skipping existing Invoice #{invoice.sequence_number}'
                   Invoice.where(sequence_number: '#{invoice.sequence_number}').first
                 else
                   puts 'Restoring missing Invoice #{invoice.sequence_number}'
                   inv_id = connection.select_value("#{dump(invoice, except: %w[id search_column], sql_suffix: "RETURNING id")}")
                   raise if inv_id.nil?

                   "#{invoice.invoice_items.map { |item| dump(item, except: %w[id invoice_id search_column], overrides: {invoice_id: '#{inv_id}'}) }.join}"
                     .split(';')
                     .each { |sql| connection.execute(sql) }

                   "#{invoice.payment_reminders.map { |reminder| dump(reminder, except: %w[id invoice_id], overrides: {invoice_id: '#{inv_id}'}) }.join}"
                     .split(';')
                     .each { |sql| connection.execute(sql) }

                   inv_id
                 end

      RUBY

      # TODO: Support manually created payments as well, maybe
      invoice.payments.where.not(status: "manually_created").find_each do |payment|
        @result << <<~RUBY
          if Payment.where(transaction_identifier: "#{payment.transaction_identifier}").exists?
            puts "Skipping existing Payment #{payment.transaction_identifier}"
          else
            puts "Restoring missing Payment #{payment.transaction_identifier}"
            payment_id = connection.select_value("#{dump(payment, except: %w[id invoice_id], overrides: {invoice_id: '#{inv_id}'}, sql_suffix: "RETURNING id")}")

            payee_sql = "#{if payment.payee
                             dump(payment.payee, except: %w[id payment_id], overrides: {payment_id: '#{payment_id}'})
                           end}"
            connection.execute(payee_sql) if payee_sql.present?
          end

        RUBY
      end

      @result << <<~RUBY
        inv_id = nil

      RUBY
    end
  end
  # rubocop:enable Metrics/MethodLength

  private

  def switch_mode(mode)
    if @result.present? && mode != @mode
      raise "Switching the mode after setting and using it is not supported."
    end

    @mode = mode
  end

  # rubocop:todo Metrics/MethodLength
  # rubocop:todo Metrics/AbcSize
  def dump(object, except: %w[search_column], overrides: {}, sql_suffix: "")
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
  # rubocop:enable Metrics/AbcSize
  # rubocop:enable Metrics/MethodLength

  def only_missing(&block)
    previous_suffix, @default_suffix = @default_suffix, "ON CONFLICT DO NOTHING"
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
    desc "Export an event with all associated things"
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
        values = attrs.map do |_key, val|
          case val
          when NilClass then "NULL"
          when String, Time, Date
            object.class.connection.quote(
              val.inspect.delete_prefix('"').delete_suffix('"')
            )
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

    desc "Export participations of an event with all associated things"
    task :participations, [:event_id] => [:environment] do |_task, args|
      dumper = BackupRestorer.new(args)
      dumper.load_event

      dumper.dump_participations
      dumper.dump_answers

      dumper.result
    end

    desc "Export invoices of a group with all associated things"
    task :invoices, [:group_id] => [:environment] do |_task, args|
      dumper = BackupRestorer.new(args)
      dumper.load_group

      dumper.dump_invoices

      dumper.result
    end
  end

  namespace :script do
    desc "Generate a script to backfill missing participations of an event and their answers"
    task :participations, [:event_id] => [:environment] do |_task, args|
      dumper = BackupRestorer.new(args)
      dumper.load_event

      dumper.script_header
      dumper.script_participations_and_answers

      dumper.result
    end

    desc "Generate a script to backfill missing invoices of a group and their associated data"
    task :invoices, [:group_id] => [:environment] do |_task, args|
      dumper = BackupRestorer.new(args)
      dumper.load_group

      dumper.script_header
      dumper.script_invoices

      dumper.result
    end
  end
end
