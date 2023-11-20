# frozen_string_literal: true

#  Copyright (c) 2023, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

require 'spec_helper'

describe Sequence do
  context '::by_name' do
    it 'creates a new sequence if it does not exist' do
      expect { Sequence.by_name('foo') }.to change { Sequence.where(name: 'foo').count }.to(1)
    end

    it 'returns the existing sequence if it exists' do
      Sequence.create!(name: 'foo')
      expect { Sequence.by_name('foo') }.not_to change { Sequence.where(name: 'foo').count }
    end

    it 'sets the current_value to 0 if it does not exist' do
      expect { Sequence.by_name('foo') }.to change { Sequence.where(name: 'foo').first&.current_value }.to(0)
    end
  end

  context '::current_value' do
    it 'returns the current_value of the sequence' do
      Sequence.create!(name: 'foo', current_value: 123)
      expect(Sequence.current_value('foo')).to eq 123
    end
  end

  context '::increment!' do
    it 'increments the current_value of the sequence' do
      Sequence.create!(name: 'foo', current_value: 123)
      expect { Sequence.increment!('foo') }.to change { Sequence.current_value('foo') }.from(123).to(124)
    end
  end

  context '#increment!' do
    it 'increments the current_value of the sequence' do
      sequence = Sequence.create!(name: 'foo', current_value: 123)
      expect { sequence.increment! }.to change { Sequence.current_value('foo') }.from(123).to(124)
    end
  end
end
