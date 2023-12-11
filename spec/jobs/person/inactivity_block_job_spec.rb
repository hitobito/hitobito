# encoding: utf-8

#  Copyright (c) 2023, Pfadibewegung Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require 'spec_helper'

describe Person::InactivityBlockJob do
  subject(:job) { described_class.new }
  subject(:block_scope) { job.block_scope(block_after&.ago) }
  let!(:person) { people(:bottom_member) }
  let(:block_after) { 1.months }
  let(:inactivity_block_warning_sent_at) { (block_after + 1.month).ago }
  before do
    allow(Person::BlockService).to receive(:block_after).and_return(block_after.to_s)
    person.update(last_sign_in_at: (block_after && block_after.ago - 1.month),
                  inactivity_block_warning_sent_at: inactivity_block_warning_sent_at)
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
    let(:inactivity_block_warning_sent_at) { nil }

    it 'ignores person' do
      expect(block_scope).not_to include(person)
      expect(job.perform).to be_truthy
    end
  end

  context 'with warning not sent' do
    let(:inactivity_block_warning_sent_at) { (block_after / 2).ago }

    it 'ignores person' do
      expect(block_scope).not_to include(person)
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
