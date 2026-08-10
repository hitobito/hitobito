#  Copyright (c) 2012-2026, Puzzle ITC. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "spec_helper"

describe AppStatus::Database do
  let(:db_status) { AppStatus::Database.new }

  context "database healthy" do
    it "is connected and has no pending migrations" do
      expect(db_status.code).to eq(:ok)

      expect(db_status.details).to eq({
        database_connected: true,
        pending_migrations: false
      })
    end
  end

  context "database unhealthy" do
    it "is not connected" do
      allow(ActiveRecord::Base).to receive(:connected?).and_return(false)

      expect(db_status.code).to eq(:service_unavailable)
      expect(db_status.details).to eq({
        database_connected: false,
        pending_migrations: false
      })
    end

    it "has pending migrations" do
      allow_any_instance_of(ActiveRecord::MigrationContext).to receive(:needs_migration?).and_return(true)

      expect(db_status.code).to eq(:service_unavailable)
      expect(db_status.details).to eq({
        database_connected: true,
        pending_migrations: true
      })
    end
  end
end
