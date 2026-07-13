# frozen_string_literal: true

#  Copyright (c) 2026, Hitobito AG. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class PersonMergeRevert
  REASSIGNED_ASSOCIATIONS = [
    {table: "roles", fk: "person_id"},
    {table: "invoices", fk: "recipient_id", fk_type: "recipient_type"},
    {table: "notes", fk: "subject_id", fk_type: "subject_type"},
    {table: "notes", fk: "author_id"},
    {table: "events", fk: "contact_id"},
    {table: "groups", fk: "contact_id"},
    {table: "family_members", fk: "person_id"},
    {table: "subscriptions", fk: "subscriber_id", fk_type: "subscriber_type"},
    {table: "event_invitations", fk: "person_id"},
    {table: "event_participations", fk: "participant_id", fk_type: "participant_type"},
    {table: "person_add_requests", fk: "person_id"},
    {table: "taggings", fk: "taggable_id", fk_type: "taggable_type"},
    {table: "qualifications", fk: "person_id"}
  ].freeze

  DUPLICATED_ASSOCIATIONS = [
    {table: "additional_emails", fk: "contactable_id", fk_type: "contactable_type"},
    {table: "phone_numbers", fk: "contactable_id", fk_type: "contactable_type"},
    {table: "social_accounts", fk: "contactable_id", fk_type: "contactable_type"},
    {table: "people_managers", fk: "managed_id"},
    {table: "people_managers", fk: "manager_id"}
  ].freeze

  EXCLUDED_COLUMNS = %w[search_column].freeze

  def initialize(duplicate_id)
    @duplicate_id = duplicate_id
  end

  def call
    load_person_ids
    [
      insert_or_update_statement(@person_1_id),
      insert_or_update_statement(@person_2_id),
      REASSIGNED_ASSOCIATIONS.flat_map { |assoc| reassigned_statements(assoc) },
      DUPLICATED_ASSOCIATIONS.flat_map { |assoc| duplicated_insert_statements(assoc) }
    ].flatten
  end

  private

  def load_person_ids
    duplicate = PersonDuplicate.find(@duplicate_id)
    @person_1_id = duplicate.person_1_id
    @person_2_id = duplicate.person_2_id
  end

  def insert_or_update_statement(person_id)
    columns = Person.column_names
    values = row_values("people", columns, person_id)
    mergable_columns = Person::MERGABLE_ATTRS.map(&:to_s) & columns
    assignments = mergable_columns.map { |c| "#{c} = EXCLUDED.#{c}" }.join(",\n  ")

    <<~SQL.strip
      INSERT INTO people
        (#{columns.join(", ")})
      VALUES
        (#{values.join(", ")})
      ON CONFLICT (id) DO UPDATE SET
        #{assignments};
    SQL
  end

  def reassigned_statements(assoc)
    table = assoc.fetch(:table)
    fk = assoc.fetch(:fk)

    [[@person_1_id, @person_2_id], [@person_2_id, @person_1_id]].flat_map do |original_id, other_id|
      row_ids_pointing_at(assoc, original_id).map do |row_id|
        set_clause = ["#{fk} = #{original_id}"]
        set_clause << "#{assoc.fetch(:fk_type)} = 'Person'" if assoc[:fk_type]

        <<~SQL.strip
          UPDATE #{table} SET
            #{set_clause.join(",\n  ")}
          WHERE id = #{row_id}
            AND #{fk} = #{other_id}#{type_condition(assoc)};
        SQL
      end
    end
  end

  def duplicated_insert_statements(assoc)
    table = assoc.fetch(:table)
    columns = ActiveRecord::Base.connection.columns(table).map(&:name) - EXCLUDED_COLUMNS

    [@person_1_id, @person_2_id].flat_map do |person_id|
      row_ids_pointing_at(assoc, person_id).map do |row_id|
        values = row_values(table, columns, row_id)

        <<~SQL.strip
          INSERT INTO #{table}
            (#{columns.join(", ")})
          VALUES
            (#{values.join(", ")})
          ON CONFLICT (id) DO NOTHING;
        SQL
      end
    end
  end

  def row_values(table, columns, id)
    connection = ActiveRecord::Base.connection
    quoted_columns = columns.map { |c| connection.quote_column_name(c) }.join(", ")
    row = ActiveRecord::Base.connection.select_one(
      "SELECT #{quoted_columns} FROM #{table} WHERE id = #{id.to_i}"
    )
    raise ActiveRecord::RecordNotFound, "#{table}##{id} not found in dump" unless row

    columns.map { |c| quote(row.fetch(c)) }
  end

  def row_ids_pointing_at(assoc, person_id)
    condition = "#{assoc.fetch(:fk)} = #{person_id}#{type_condition(assoc)}"
    ActiveRecord::Base.connection.select_values(
      "SELECT id FROM #{assoc.fetch(:table)} WHERE #{condition}"
    )
  end

  def type_condition(assoc)
    return "" unless assoc[:fk_type]

    " AND #{assoc.fetch(:fk_type)} = 'Person'"
  end

  def quote(value)
    case value
    when nil then "NULL"
    when true, false then value.to_s
    else Person.connection.quote(value)
    end
  end
end

namespace :person_merge_revert do
  desc "Print SQL statements from a dumped DB state to revert person merge"
  task :run, [:duplicate_id] => [:environment] do |_task, args|
    duplicate_id = args.fetch(:duplicate_id) { abort("You need to pass a duplicate_id to revert") }

    statements = PersonMergeRevert.new(duplicate_id).call

    puts statements.join("\n\n")
  end
end
