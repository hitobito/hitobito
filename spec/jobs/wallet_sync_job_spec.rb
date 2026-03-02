#  Copyright (c) 2026, Puzzle ITC. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "spec_helper"

describe WalletSyncJob do
  let(:person) { people(:top_leader) }
  let(:definition) { Fabricate(:pass_definition, owner: groups(:top_layer)) }
  let(:pass) do
    Fabricate(:pass,
      person: person,
      pass_definition: definition,
      state: :eligible,
      valid_from: 1.month.ago.to_date)
  end
  let!(:pending_installation) do
    Fabricate(:wallets_pass_installation,
      pass: pass,
      wallet_type: :apple,
      needs_sync: true)
  end

  subject(:job) { described_class.new }

  before do
    stub_const("Wallets::GoogleWallet::PassService", Class.new)
  end

  it "syncs all pending installations" do
    job.perform_internal
    pending_installation.reload

    expect(pending_installation.state).to eq("active")
    expect(pending_installation.last_synced_at).to be_present
  end

  it "continues processing when one installation fails" do
    pass2 = Fabricate(:pass,
      person: Fabricate(:person),
      pass_definition: definition,
      state: :eligible,
      valid_from: 1.month.ago.to_date)
    _good_installation = Fabricate(:wallets_pass_installation,
      pass: pass2,
      wallet_type: :apple,
      needs_sync: true)

    # Make the first installation fail by making its pass invalid
    allow_any_instance_of(Wallets::PassSynchronizer).to receive(:sync!).and_call_original
    call_count = 0
    allow_any_instance_of(Wallets::PassSynchronizer).to receive(:sync!).and_wrap_original do |method, *args|
      call_count += 1
      if call_count == 1
        raise StandardError, "transient error"
      else
        method.call(*args)
      end
    end

    job.perform_internal

    # Second installation should still have been processed
    expect(call_count).to eq(2)
  end

  it "is a RecurringJob" do
    expect(described_class.superclass).to eq(RecurringJob)
  end
end
