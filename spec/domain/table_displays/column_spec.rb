# frozen_string_literal: true

#  Copyright (c) 2012-2025, Schweizer Blasmusikverband. This file is part of
#  hitobito_sbv and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "spec_helper"

describe TableDisplays::Column do
  let(:ability) { double(:ability) }

  before do
    stub_const("TestColum", Class.new(TableDisplays::Column))
  end

  subject(:column) { TestColum.new(ability, model_class: Person) }

  describe "#safe_required_model_attrs" do
    it "is empty when nothing is specified" do
      expect(column.safe_required_model_attrs(:column)).to be_empty
    end

    it "returns column if defined on model" do
      allow(column).to receive(:required_model_attrs).and_return(%w[first_name])
      expect(column.safe_required_model_attrs(:column)).to eq %w[first_name]
    end

    it "returns multiple columns if all defined on model" do
      allow(column).to receive(:required_model_attrs).and_return(%w[first_name last_name])
      expect(column.safe_required_model_attrs(:column)).to eq %w[first_name last_name]
    end

    it "returns fq column if defined on model" do
      allow(column).to receive(:required_model_attrs).and_return(%w[people.first_name])
      expect(column.safe_required_model_attrs(:column)).to eq %w[people.first_name]
    end

    it "strips out column not defined on model" do
      allow(column).to receive(:required_model_attrs).and_return(%w[first_name foobar])
      expect(column.safe_required_model_attrs(:column)).to eq %w[first_name]
    end

    it "strips out fq column not defined on model" do
      allow(column).to receive(:required_model_attrs).and_return(%w[first_name roles.id])
      expect(column.safe_required_model_attrs(:column)).to eq %w[first_name]
    end
  end
end
