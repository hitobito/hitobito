#  Copyright (c) 2012-2020, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require 'spec_helper'

describe CurrencyHelper do

  it 'uses unit from settings' do
    expect(number_to_currency(10)).to eq 'CHF 10.00'
    allow(Settings.currency).to receive(:unit).and_return('$')
    expect(number_to_currency(10)).to eq '$ 10.00'
  end

end

