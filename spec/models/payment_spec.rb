# encoding: utf-8

#  Copyright (c) 2012-2017, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require 'spec_helper'

describe Payment do
  let(:invoice) { invoices(:sent) }

  it 'creating a big enough payment marks invoice as payed' do
    expect do
      invoice.payments.create!(amount: invoice.total)
    end.to change { invoice.state }
    expect(invoice.state).to eq 'payed'
  end

  it 'creating a smaller payment does not change invoice state' do
    expect do
      invoice.payments.create!(amount: invoice.total - 1)
    end.not_to change { invoice.state }
  end

end
