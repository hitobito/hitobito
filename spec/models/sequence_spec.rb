# frozen_string_literal: true

#  Copyright (c) 2023, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

require 'spec_helper'

describe Sequence do
  context '::current_value' do
    it 'returns the current_value of the sequence' do
      expect(Sequence.current_value('household_sequence')).to eq 1
    end
  end

  context '::increment!' do
    it 'increments the current_value of the sequence' do
      expect { Sequence.increment!('household_sequence') }.to change { Sequence.current_value('household_sequence') }.from(nil).to(1)
    end
  end
end
