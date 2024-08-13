# frozen_string_literal: true

#  Copyright (c) 2023, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

require "spec_helper"

describe Sequence do

  setup do
    ActiveRecord::Base.connection.execute("CREATE SEQUENCE test_sequence START 1")
    Sequence.increment!('test_sequence')
  end

  context '::current_value' do
    it 'returns the current_value of the sequence' do
      expect(Sequence.current_value('test_sequence')).to eq 1
    end
  end

  context '::increment!' do
    it 'increments the current_value of the sequence' do
      Sequence.increment!('test_sequence')
      Sequence.increment!('test_sequence')
      expect(Sequence.current_value('test_sequence')).to eq 3
    end
  end
end
