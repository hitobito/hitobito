# frozen_string_literal: true

#  Copyright (c) 2012-2020, CVP Schweiz. This file is part of
#  hitobito_cvp and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_cvp.

require 'spec_helper'

describe Invoice::ScorReference do

  it 'succeeds for valid sequence value' do
    expect(described_class.create('test')).to eq 'RF55TEST'
  end

  it 'fails for invalid char' do
    expect { described_class.create('test-1') }.to raise_error(/^Invalid characters/)
  end

  it 'fails if string is blank' do
    expect { described_class.create('') }.to raise_error(/^Invalid size/)
  end

  it 'fails if string is too long' do
    expect { described_class.create('A' * 26) }.to raise_error(/^Invalid size/)
  end

end
