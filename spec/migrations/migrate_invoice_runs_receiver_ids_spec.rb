#  Copyright (c) 2026, Hitobito AG. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito

require "rails_helper"
require_relative "../../db/migrate/20260119074903_migrate_invoice_runs_receiver_ids"

RSpec.describe MigrateInvoiceRunsReceiverIds, type: :migration do
  let(:migration_context) { ActiveRecord::Base.connection_pool.migration_context }
  let(:migration_version) { 20260119074903 }
  let(:previous_version) do
    versions = migration_context.migrations.map(&:version)
    index = versions.index(migration_version)
    (index > 0) ? versions[index - 1] : 0
  end

  before do
    migration_context.down(previous_version)
    InvoiceRun.reset_column_information
  end

  after do
    migration_context.up
    InvoiceRun.reset_column_information
  end

  context "invoice_runs with group as receiver" do
    let!(:group_invoice_run) do
      ActiveRecord::Base.connection.execute(<<-SQL)
        INSERT INTO invoice_runs (title, receiver_id, receiver_type, created_at, updated_at)
        VALUES ('InvoiceRun', #{groups(:top_layer).id}, 'Group', NOW(), NOW())
      SQL
      InvoiceRun.last
    end
    let!(:mailing_list_invoice_run) do
      ActiveRecord::Base.connection.execute(<<-SQL)
        INSERT INTO invoice_runs (title, receiver_id, receiver_type, created_at, updated_at)
        VALUES ('InvoiceRun', #{mailing_lists(:leaders).id}, 'MailingList', NOW(), NOW())
      SQL
      InvoiceRun.last
    end

    it "does create people_filter in certain group and update association of invoice_run" do
      expect do
        migration_context.up(migration_version)
      end.to change { PeopleFilter.count }.by(1)

      new_people_filter = PeopleFilter.last

      expect(new_people_filter.visible).to be_falsey
      expect(new_people_filter.range).to eq "group"
      expect(new_people_filter.group_id).to eq groups(:top_layer).id

      expect(group_invoice_run.reload.recipient_source_type).to eq "PeopleFilter"
      expect(group_invoice_run.reload.recipient_source_id).to eq new_people_filter.id
    end

    it "does create multiple people_filters when multiple invoice_runs in same group" do
      ActiveRecord::Base.connection.execute(<<-SQL)
        INSERT INTO invoice_runs (title, receiver_id, receiver_type, created_at, updated_at)
        VALUES ('InvoiceRun 2', #{groups(:top_layer).id}, 'Group', NOW(), NOW())
      SQL
      group_invoice_run_2 = InvoiceRun.last

      expect do
        migration_context.up(migration_version)
      end.to change { PeopleFilter.count }.by(2)

      expect(group_invoice_run.reload.recipient_source_id).not_to eq group_invoice_run_2.reload.recipient_source_id
    end

    it "does not migrate invoice_run when receiver_type is not group" do
      group_invoice_run.destroy!

      expect do
        migration_context.up(migration_version)
      end.not_to change { PeopleFilter.count }
    end
  end

  context "invoice_runs with receivers" do
    let!(:receivers_invoice_run) do
      ActiveRecord::Base.connection.execute(<<-SQL)
        INSERT INTO invoice_runs (title, receivers, group_id, created_at, updated_at)
        VALUES ('InvoiceRun 2', #{ActiveRecord::Base.connection.quote([
          {id: people(:top_leader).id, layer_group_id: people(:top_leader).layer_group.id},
          {id: people(:bottom_member).id, layer_group_id: people(:top_leader).layer_group.id}
        ].to_yaml)}, #{groups(:top_layer).id}, NOW(), NOW())
      SQL

      InvoiceRun.last
    end

    it "does create people_filter with correct filter_chain and update association of invoice_run" do
      expect do
        migration_context.up(migration_version)
      end.to change { PeopleFilter.count }.by(1)

      new_people_filter = PeopleFilter.last

      expect(new_people_filter.visible).to be_falsey
      expect(new_people_filter.range).to eq "deep"
      expect(new_people_filter.group_id).to eq groups(:top_layer).id
      expect(new_people_filter.to_params).to eq({
        name: nil,
        range: "deep",
        filters: {
          "attributes" => {
            "0" => {
              "key" => "id",
              "constraint" => "include",
              "value" => [people(:top_leader).id, people(:bottom_member).id]
            }
          }
        }
      })

      expect(receivers_invoice_run.reload.recipient_source_type).to eq "PeopleFilter"
      expect(receivers_invoice_run.reload.recipient_source_id).to eq new_people_filter.id
    end

    it "does not migrate invoice_run when receivers are empty" do
      ActiveRecord::Base.connection.execute(<<-SQL)
        UPDATE invoice_runs
        SET receivers = '--- []\n'
        WHERE id = #{receivers_invoice_run.id}
      SQL

      expect do
        migration_context.up(migration_version)
      end.not_to change { PeopleFilter.count }
    end
  end
end
