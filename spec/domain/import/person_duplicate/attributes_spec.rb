# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of hitobito and licensed under the
#  Affero General Public License version 3 or later. See the COPYING file at the top-level directory
#  or at https://github.com/hitobito/hitobito.

require "spec_helper"

describe Import::PersonDuplicate::Attributes do
  def duplicate_conditions(attrs)
    described_class.new(attrs).duplicate_conditions
  end

  context "working", :focus do
    it "works" do
      expect(duplicate_conditions({first_name: "test"})).to eq ["first_name = ?", "test"]
    end

    it "works for second params" do
      expect(duplicate_conditions({last_name: "test"})).to eq ["last_name = ?", "test"]
    end
  end

  it "builds query for names as from symbol or string hash" do
    expect(duplicate_conditions({})).to eq [""]
    expect(duplicate_conditions({first_name: "test"})).to eq ["first_name = ?", "test"]
    expect(duplicate_conditions({last_name: "test"})).to eq ["last_name = ?", "test"]
    expect(duplicate_conditions({company_name: "test"})).to eq ["company_name = ?", "test"]
    expect(duplicate_conditions({first_name: "test", company_name: "test"})).to eq ["first_name = ? AND company_name = ?", "test", "test"]
    expect(duplicate_conditions({first_name: "test", last_name: "test", company_name: "test"})).to eq ["first_name = ? AND last_name = ? AND company_name = ?", "test", "test", "test"]
    expect(duplicate_conditions({first_name: "test", last_name: "test", company_name: "test"}.stringify_keys)).to eq ["first_name = ? AND last_name = ? AND company_name = ?", "test", "test", "test"]
  end

  describe "birthday" do
    it "is ignored if invalid" do
      expect(duplicate_conditions({birthday: ""})).to eq [""]
      expect(duplicate_conditions({birthday: "1"})).to eq [""]
      expect(duplicate_conditions({birthday: "test"})).to eq [""]
      expect(duplicate_conditions({birthday: "33.33.33"})).to eq [""]
    end

    it "is used as null or identical" do
      expect(duplicate_conditions({birthday: ""})).to eq [""]
      expect(duplicate_conditions({birthday: "1"})).to eq [""]
      expect(duplicate_conditions({birthday: "2000-12-31"})).to eq ["(birthday = ? OR birthday IS NULL)", Date.new(2000, 12, 31)]
    end

    it "accepts 00 based birthday" do
      expect(duplicate_conditions({birthday: "1.1.00"})).to eq ["(birthday = ? OR birthday IS NULL)", Date.new(2000, 1, 1)]
    end

    it "is combined with AND with other conditions" do
      expect(duplicate_conditions({first_name: "test", birthday: "2000-12-31"})).to eq ["first_name = ? AND (birthday = ? OR birthday IS NULL)", "test", Date.new(2000, 12, 31)]
    end
  end

  describe "email" do
    it "is used if present if invalid" do
      expect(duplicate_conditions({email: "test"})).to eq ["email = ?", "test"]
    end

    it "is combined with OR with other conditions" do
      expect(duplicate_conditions({first_name: "first", email: "test"})).to eq ["(first_name = ?) OR email = ?", "first", "test"]
      expect(duplicate_conditions({first_name: "first", email: "test", birthday: "2000-1-1"})).to eq ["(first_name = ? AND (birthday = ? OR birthday IS NULL)) OR email = ?", "first", Date.new(2000), "test"]
    end
  end
end
