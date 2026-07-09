# frozen_string_literal: true

#  Copyright (c) 2012-2021, CVP Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.
#
require "spec_helper"

describe Address do
  it "serializes numbers as array" do
    bs_bern = addresses(:bs_bern)
    expect(bs_bern.numbers).to eq %w[36 37 38 40 41 5a 5b 6A 6B]
  end

  context "#zip_code" do
    it "stores and reads Swiss zip codes (4 digits)" do
      address = Fabricate(:address, zip_code: 3007)
      expect(address.reload.zip_code).to eq "3007"
    end

    it "stores and reads zip codes with leading zero" do
      address = Fabricate(:address, zip_code: "01234")
      expect(address.reload.zip_code).to eq "01234"
    end

    it "stores and reads alphanumeric zip codes" do
      address = Fabricate(:address, zip_code: "A1234")
      expect(address.reload.zip_code).to eq "A1234"
    end
  end
end
