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

  it "grants no role access to existing questions" do
    application_question = Fabricate(:event_question, event: events(:top_course))
    admin_question = Fabricate(:event_question, event: events(:top_course), admin: true)

    migration_context.up(migration_version)

    expect(backfilled_role_types(application_question)).to eq []
    expect(backfilled_role_types(admin_question)).to eq []
  end
end
