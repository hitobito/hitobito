# frozen_string_literal: true

#  Copyright (c) 2012-2026, Puzzle ITC. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class AppStatus::Database
  def initialize
    super

    @database_connected = database_connected?
    @pending_migrations = pending_migrations?
  end

  def code
    return AppStatus::SERVICE_UNAVAILABLE unless @database_connected

    @pending_migrations ? AppStatus::SERVICE_UNAVAILABLE : AppStatus::OK
  end

  def details
    {
      database_connected: @database_connected,
      pending_migrations: @pending_migrations
    }
  end

  private

  def database_connected?
    ActiveRecord::Base.connected?
  end

  def pending_migrations?
    ActiveRecord::Base.connection_pool.migration_context.needs_migration?
  end
end
