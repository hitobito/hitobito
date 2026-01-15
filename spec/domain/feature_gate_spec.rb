# frozen_string_literal: true

#  Copyright (c) 2022, Schweizer Wanderwege. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "spec_helper"

describe FeatureGate do
  context "self_registration_reason" do
    def remove_cached_class_variable
      if FeatureGate.class_variable_defined?(:@@self_registration_enabled)
        FeatureGate.remove_class_variable(:@@self_registration_enabled)
      end
    end

    around do |example|
      remove_cached_class_variable
      example.run
      remove_cached_class_variable
    end

    it "is enabled when SelfRegistrationReason exists" do
      expect(SelfRegistrationReason.count).to be > 0
      expect(FeatureGate.enabled?(:self_registration_reason)).to eq(true)
    end

    it "is disabled when SelfRegistrationReason does not exist" do
      SelfRegistrationReason.delete_all
      expect(FeatureGate.enabled?(:self_registration_reason)).to eq(false)
    end
  end
end
