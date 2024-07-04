# frozen_string_literal: true

#  Copyright (c) 2012-2021, CVP Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.
#
# == Schema Information
#
# Table name: addresses
#
#  id               :bigint           not null, primary key
#  street_short     :string(128)      not null
#  street_short_old :string(128)      not null
#  street_long      :string(128)      not null
#  street_long_old  :string(128)      not null
#  town             :string(128)      not null
#  zip_code         :integer          not null
#  state            :string(128)      not null
#  numbers          :text(16777215)
#

require "spec_helper"

describe Address do
  it "serializes numbers as array" do
    bs_bern = addresses(:bs_bern)
    expect(bs_bern.numbers).to eq %w[36 37 38 40 41 5a 5b 6A 6B]
  end
end
