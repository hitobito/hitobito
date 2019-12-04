# encoding: utf-8

#  Copyright (c) 2012-2019, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require 'spec_helper'

describe Invoice::Filter do
  let(:invoice) { invoices(:invoice) }
  let(:year)    { Date.today.year }


  it 'filters by year' do
    invoice.update(issued_at: 1.year.ago)
    filtered = Invoice::Filter.new(year: year).apply(Invoice)
    expect(filtered.count).to eq 1
  end
end
