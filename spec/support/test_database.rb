# frozen_string_literal: true

#  Copyright (c) 2026, Puzzle ITC. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito

# Prepares the test database once before the suite runs, so every run starts from the same,
# well defined state: all tables are truncated, then the fixtures and finally the seeds
# registered by wagons (via `config.seeds << {paths: [...], filter: /.../}`) are loaded.
#
# Truncating everything removes leftovers of earlier runs (e.g. data committed outside of the
# transactional fixtures), so seeds inserted with `seed_once` are always created completely
# and no table has to be cleaned selectively. Fixtures and seeds are committed, so they survive
# the rollback of the transaction wrapping each example.
module TestDatabase
  module_function

  # Fixtures must be loaded before the seeds: loading fixtures deletes all rows of every table
  # having a fixture file (e.g. action_text_rich_texts), which would wipe seeded data stored there
  # (e.g. the bodies of seeded custom contents). Loaded here, the fixture sets are cached, so the
  # fixture setup of the first example finds them already loaded and does not delete anything.
  def prepare(config)
    truncate_all
    load_fixtures(config)
    load_seeds(config.seeds)
  end

  def truncate_all
    connection = ActiveRecord::Base.connection
    connection.truncate_tables(*connection.tables)
  end

  def load_fixtures(config)
    loader = Class.new do
      include ActiveRecord::TestFixtures

      self.fixture_paths = config.fixture_paths
      fixtures :all
    end

    ActiveRecord::FixtureSet.reset_cache
    ActiveRecord::FixtureSet.create_fixtures(
      loader.fixture_paths,
      loader.fixture_table_names,
      loader.fixture_class_names
    )
  end

  def load_seeds(seeds)
    SeedFu.quiet = true
    seeds.each { |seed| SeedFu.seed(seed.fetch(:paths), seed[:filter]) }
  end
end
