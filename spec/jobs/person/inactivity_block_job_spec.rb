# encoding: utf-8
# frozen_string_literal: true

#  Copyright (c) 2023, Pfadibewegung Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require 'spec_helper'

describe Person::InactivityBlockJob do
  subject(:job) { described_class.new }
  subject(:block_scope) { job.block_scope }
  let!(:person) { people(:bottom_member) }
  let(:block_after) { 6.months }
  let(:last_sign_in_at) {  }
  before do
    allow(Person::BlockService).to receive(:block_after).and_return(block_after)
    person.update(last_sign_in_at: last_sign_in_at)
  end

  context 'with warned inactive person' do
    let(:block_service){ double("BlockService") }

    it 'blocks the person' do
      expect(Person::BlockService).to receive(:new).with(person).and_return(block_service)
      expect(block_service).to receive(:block!)
      expect(block_scope).to include(person)
      expect(job.perform).to be_truthy
    end
  end

  context 'with already blocked person' do
    before { Person::BlockService.new(person).block! }

    it 'ignores person' do
      expect(block_scope).not_to include(person)
      expect(job.perform).to be_truthy
    end
  end

  context 'with active person' do
    before { person.touch(:last_sign_in_at) }

    it 'ignores person' do
      expect(block_scope).not_to include(person)
      expect(job.perform).to be_truthy
    end
  end

  context 'with warning not sent' do
    before { person.update(inactivity_block_warning_sent_at: nil) }

    it 'includes person' do
      expect(block_scope).to include(person)
      expect(job.perform).to be_truthy
    end
  end

  context 'with no block_after set' do
    let(:inactivity_block_warning_sent_at) { nil }
    let(:block_after) { nil }

    it 'returns early' do
      expect(Person::BlockService).not_to receive(:new)
      expect(job.perform).to be_falsy
    end
  end
end
