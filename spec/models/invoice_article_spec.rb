# encoding: utf-8

#  Copyright (c) 2017, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "spec_helper"

RSpec.describe InvoiceArticle, type: :model do
  subject { invoice_articles(:beitrag)}

  it "has a nice string represenation" do
    expect(subject.to_s).to eq "BEI-18 - Beitrag Erwachsene"
  end

end
