# frozen_string_literal: true

#  Copyright (c) 2026, CEVI Regionalverband ZH-SH-GL. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "rails_helper"
require_relative "../../db/migrate/20260708160000_create_event_question_visibilities"

RSpec.describe CreateEventQuestionVisibilities, type: :migration do
  let(:migration_context) { ActiveRecord::Base.connection_pool.migration_context }
  let(:migration_version) { 20260708160000 }
  let(:previous_version) do
    versions = migration_context.migrations.map(&:version)
    index = versions.index(migration_version)
    (index > 0) ? versions[index - 1] : 0
  end

  let(:expected_role_types) do
    Event::Role.descendants
      .select { |role_type| role_type.permissions.include?(:participations_read_details) }
      .map(&:sti_name)
  end

  before do
    ActiveRecord::Migration.verbose = false
    migration_context.down(previous_version)
    ActiveRecord::Base.connection.schema_cache.clear!
    ActiveRecord::Base.descendants.each(&:reset_column_information)
  end

  after do
    migration_context.up
    ActiveRecord::Base.connection.schema_cache.clear!
    ActiveRecord::Base.descendants.each(&:reset_column_information)
    ActiveRecord::Migration.verbose = true
  end

  def backfilled_role_types(question)
    ActiveRecord::Base.connection.select_all(
      "SELECT role_type FROM event_question_visibilities WHERE question_id = #{question.id}"
    ).rows.flatten
  end

  it "backfills existing questions with the roles that today grant show_details" do
    question = Fabricate(:event_question, event: events(:top_course))

    migration_context.up(migration_version)

    expect(backfilled_role_types(question)).to match_array(expected_role_types)
  end

  it "does not backfill roles without the participations_read_details permission" do
    question = Fabricate(:event_question, event: events(:top_course))

    migration_context.up(migration_version)

    expect(backfilled_role_types(question)).not_to include(
      Event::Role::Leader.sti_name,
      Event::Role::AssistantLeader.sti_name,
      Event::Role::Speaker.sti_name,
      Event::Role::Treasurer.sti_name,
      Event::Role::Participant.sti_name
    )
  end

  it "backfills every existing question, not just newly created ones" do
    question_1 = Fabricate(:event_question, event: events(:top_course))
    question_2 = Fabricate(:event_question, event: events(:top_course))

    migration_context.up(migration_version)

    expect(backfilled_role_types(question_1)).to match_array(expected_role_types)
    expect(backfilled_role_types(question_2)).to match_array(expected_role_types)
  end
end
