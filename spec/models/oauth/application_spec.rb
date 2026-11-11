# frozen_string_literal: true

#  Copyright (c) 2026, Schweizer Alpen-Club. This file is part of hitobito and licensed under the
#  Affero General Public License version 3 or later. See the COPYING file at the top-level directory
#  or at https://github.com/hitobito/hitobito.

require "spec_helper"

describe Oauth::Application do
  subject(:application) { Fabricate.build(:application) }

  describe "refresh_token_lifetime_days" do
    it "is valid when blank" do
      application.refresh_token_lifetime_days = nil
      expect(application).to be_valid
    end

    it "is valid with a positive number of days" do
      application.refresh_token_lifetime_days = 180
      expect(application).to be_valid
    end

    it "is invalid with zero days" do
      application.refresh_token_lifetime_days = 0
      expect(application).not_to be_valid
    end

    it "is invalid with fractional days" do
      application.refresh_token_lifetime_days = 1.5
      expect(application).not_to be_valid
    end
  end

  describe "#refresh_token_lifetime" do
    it "uses the configured days" do
      application.refresh_token_lifetime_days = 180
      expect(application.refresh_token_lifetime).to eq 180.days
    end

    it "falls back to the default lifetime" do
      application.refresh_token_lifetime_days = nil
      expect(application.refresh_token_lifetime).to eq 7.days
    end
  end
end
