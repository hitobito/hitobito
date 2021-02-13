# encoding: utf-8

#  Copyright (c) 2012-2017, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "spec_helper"

describe Export::Tabular::Events::Row do

  let(:max_dates) { 3 }
  let(:contactable_keys) { [:name, :address, :zip_code, :town, :email, :phone_numbers] }
  let(:person) { Fabricate(:person_with_address_and_phone) }
  let(:course) do
    Fabricate(:course, state: "some state", groups: [groups(:top_group)],
              description: "some description", number: 123, location: "somewhere")
  end

  let(:row) { Export::Tabular::Events::Row.new(course) }

  subject { row }

  shared_context "contactable" do
    def value(key)
      row.fetch(:"#{prefix}_#{key}")
    end

    describe "without value" do
      specify "keys" do
        contactable_keys.each { |key| expect(value(key)).to be_nil }
      end
    end
  end

  shared_examples_for "contactable with value" do
    specify "values" do
      expect(value(:name)).to eq contactable.to_s
      expect(value(:email)).to eq contactable.email
      expect(value(:address)).to eq contactable.address
      expect(value(:zip_code)).to eq contactable.zip_code
      expect(value(:town)).to eq contactable.town
      expect(value(:phone_numbers)).to eq contactable.phone_numbers.map(&:to_s).join(", ")
    end
  end

  context "event attributes" do
    it { expect(row.fetch(:kind)).to eq "Scharleiterkurs" }
    it { expect(row.fetch(:state)).to eq "some state" }
    it { expect(row.fetch(:number)).to eq "123" }
    it { expect(row.fetch(:location)).to eq "somewhere" }
    it { expect(row.fetch(:description)).to eq "some description" }
    it { expect(row.fetch(:group_names)).to eq "TopGroup" }
  end

  context "contact person" do
    include_context "contactable"

    let(:prefix) { :contact }

    context "with contact" do
      let(:contactable) { person }
      before { course.contact = person }
      it_should_behave_like "contactable with value"
    end
  end

  context "leader" do
    include_context "contactable"

    let(:prefix) { :leader }

    context "with leader" do
      let(:participation) { Fabricate(:event_participation, event: course) }
      let!(:contactable) { Fabricate(Event::Role::Leader.name.to_sym, participation: participation).person }
      it_should_behave_like "contactable with value"
    end
  end

  context "dates" do
    let(:start_at) { Date.parse "Sun, 09 Jun 2013" }
    let(:finish_at) { Date.parse "Wed, 12 Jun 2013" }
    let(:date) { Fabricate(:event_date, event: course, start_at: start_at, finish_at: finish_at) }

    before { allow(course).to receive_messages(dates: [date]) }

    it { expect(row.fetch(:date_0_label)).to eq "Hauptanlass" }
    it { expect(row.fetch(:date_0_duration)).to eq "09.06.2013 - 12.06.2013" }

    it "has keys for two more dates" do
      expect(row.fetch(:date_1_label)).to eq nil
      expect(row.fetch(:date_2_label)).to eq nil
    end
  end

end
