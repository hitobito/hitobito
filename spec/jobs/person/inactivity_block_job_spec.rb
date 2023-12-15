# encoding: utf-8
# frozen_string_literal: true

#  Copyright (c) 2023, Pfadibewegung Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require 'spec_helper'

describe Person::InactivityBlockJob do
  subject(:job) { described_class.new }
  let!(:person) { people(:bottom_member) }
  let(:block_after_value) { 6.months }
  let(:last_sign_in_at) { block_after_value&.+(3.months)&.ago }

  before do
    allow(Person::BlockService).to receive(:block_after).and_return(block_after_value)
    person.update(last_sign_in_at: last_sign_in_at)
  end

  context "with no block_after set" do
    let(:block_after_value) { nil }
    it { expect(job.perform).to be_falsy }
    it { expect(Person::BlockService).not_to receive(:new) }
  end

  context "with block_after set" do
    let(:block_after_value) { 6.months }
    let(:block_service) { double("BlockService") }
    before do
      expect(Person::BlockService).to receive(:new).with(person).and_return(block_service)
      expect(block_service).to receive(:block!)
    end

    it { expect(job.perform).to be_truthy }
  end
end
