#  Copyright (c) 2026, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "spec_helper"
require_relative "../../db/migrate/20261026095543_create_missing_invoice_configs"

describe CreateMissingInvoiceConfigs do
  let(:layer) { groups(:bottom_layer_one) }

  before { ActiveRecord::Migration.verbose = false }

  after { ActiveRecord::Migration.verbose = true }

  it "creates invoice config for layer group without one" do
    layer.invoice_config.delete
    expect { described_class.new.up }.to change { InvoiceConfig.count }.by(1)
    expect(layer.reload.invoice_config).to be_present
  end

  it "keeps existing invoice config of layer group" do
    config = layer.invoice_config
    described_class.new.up
    expect(layer.reload.invoice_config).to eq config
  end

  it "skips non layer and deleted layer groups" do
    deleted_layer = Fabricate(Group::BottomLayer.sti_name, parent: groups(:top_layer))
    deleted_layer.destroy
    expect { described_class.new.up }.not_to change { InvoiceConfig.count }
  end
end
