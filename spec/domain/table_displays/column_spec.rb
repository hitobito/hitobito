# frozen_string_literal: true

#  Copyright (c) 2012-2025, Schweizer Blasmusikverband. This file is part of
#  hitobito_sbv and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "spec_helper"

describe TableDisplays::Column do
  describe "::valid?" do
    it "is true when required_model_attrs is empty" do
      expect(described_class.valid?(Person, :first_name)).to eq true
    end

    it "is true when required_model_attrs return array with column on that table" do
      allow_any_instance_of(described_class).to receive(:required_model_attrs).and_return(%w[first_name])
      expect(described_class.valid?(Person, :first_name)).to eq true
    end

    it "is true when required_model_attrs return array with fqn of column on that table" do
      allow_any_instance_of(described_class).to receive(:required_model_attrs).and_return(%w[people.first_name])
      expect(described_class.valid?(Person, :first_name)).to eq true
    end

    it "is true when required_model_attrs return array with column not on that table" do
      allow_any_instance_of(described_class).to receive(:required_model_attrs).and_return(%w[foobar])
      expect(described_class.valid?(Person, :first_name)).to eq false
    end

    it "is true when required_model_attrs return array with fqn of column not on that table" do
      allow_any_instance_of(described_class).to receive(:required_model_attrs).and_return(%w[people.foobar])
      expect(described_class.valid?(Person, :first_name)).to eq false
    end
  end
end
