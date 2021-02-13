# frozen_string_literal: true

#  Copyright (c) 2012-2020, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "spec_helper"

describe Import::PersonDuplicateFinder do
  let(:finder) { Import::PersonDuplicateFinder.new }
  subject { finder.find(attrs) }

  let(:conditions) { finder.send(:duplicate_conditions, attrs)}

  context "empty attrs" do
    let(:attrs) { {} }
    it { expect(conditions).to eq [""] }
    it { is_expected.to be_nil }
  end

  context "firstname only" do
    before { Person.create!(attrs)  }
    let(:attrs) { { first_name: "foo" } }
    it { expect(conditions).to eq ["first_name = ?", "foo"] }
    it { is_expected.to be_present }
    it "has no error" do
      expect(subject.errors.size).to eq(0)
    end
  end

  context "email only" do
    before { Person.create!(attrs.merge(first_name: "foo")) }
    let(:attrs) { { email: "foo@bar.com" } }
    it { expect(conditions).to eq ["email = ?", "foo@bar.com"] }
    it { is_expected.to be_present }
    it "has no error" do
      expect(subject.errors.size).to eq(0)
    end
  end

  context "adding new doublette attrs" do
    before { Person.create!(first_name: "foo", last_name: "Bar") }
    let(:attrs) { { first_name: "foo", last_name: "Bar", zip_code: "3000" } }
    its("errors.full_messages") { should eq [] }
    it { is_expected.to be_present }
    it "has no error" do
      expect(subject.errors.size).to eq(0)
    end
  end

  context "joins with or clause, does not change first_name, adds nickname" do
    before { Person.create!(attrs.merge(first_name: "foo", nickname: "foobar")) }
    let(:attrs) { { email: "foo@bar.com", first_name: "bla" } }
    it { expect(conditions).to eq ["(first_name = ?) OR email = ?", "bla", "foo@bar.com"] }
    it { is_expected.to be_present }
    it "has no error" do
      expect(subject.errors.size).to eq(0)
    end
  end

  context "joins others with and" do
    context "includes valid birthday" do
      before { Person.create!(attrs) }
      let(:attrs) { { last_name: "bar", first_name: "foo", zip_code: "8000", birthday: "1991-05-06" } }
      it do
         expect(conditions).to eq([
           "last_name = ? AND first_name = ? AND (zip_code = ? OR zip_code IS NULL) " \
           "AND (birthday = ? OR birthday IS NULL)",
           "bar", "foo", "8000", Time.zone.parse("1991-05-06").to_date])
      end
      it { is_expected.to be_present }
      it "has no error" do
        expect(subject.errors.size).to eq(0)
      end
    end

    context "ignores invalid birthday" do
      before { Person.create!(attrs.merge(birthday: "2000-01-01")) }
      let(:attrs) { { last_name: "bar", first_name: "foo", zip_code: "8000", birthday: "33.33.33" } }

      it do
        expect(conditions).to eq([
          "last_name = ? AND first_name = ? AND (zip_code = ? OR zip_code IS NULL)",
          "bar", "foo", "8000"])
      end
      it { is_expected.to be_present }
      it "has no error" do
        expect(subject.errors.size).to eq(0)
      end
    end

    context "accepts two-digit year birthday" do
      before { Person.create!(attrs.merge(birthday: "2000-01-01")) }
      let(:attrs) { { last_name: "bar", first_name: "foo", zip_code: "8000", birthday: "1.1.00" } }

      it do
        expect(conditions).to eq([
          "last_name = ? AND first_name = ? AND (zip_code = ? OR zip_code IS NULL) " \
           "AND (birthday = ? OR birthday IS NULL)",
          "bar", "foo", "8000", Time.zone.parse("2000-01-01").to_date])
      end
      it { is_expected.to be_present }
      it "has no error" do
        expect(subject.errors.size).to eq(0)
      end
    end
  end

  context "multiple doublettes for the same person" do
    let(:attrs) { { first_name: "Peter", last_name: "Meier" } }

    before do
      Person.create!(attrs)
      Person.create!(attrs)
    end

    it { is_expected.to be_present }
    it "has 1 error" do
      expect(subject.errors.size).to eq(1)
    end
  end

  context "multiple updates to the same person" do
    let(:existing) { Person.create!(attrs.merge(first_name: "foo")) }
    let(:attrs) { { email: "foo@bar.com" } }

    before do
      existing
      @first = finder.find(attrs)
    end
    it { is_expected.to be @first }
  end

end
