# encoding: utf-8

#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require 'spec_helper'
describe Export::Csv::Events::Row do

  let(:max_dates) { 3 }
  let(:contactable_keys) { [:name, :address, :zip_code, :town, :email, :phone_numbers] }
  let(:person) { Fabricate(:person_with_address_and_phone) }
  let(:course) do
    Fabricate(:course, state: 'some state', groups: [groups(:top_group)],
              description: 'some description', number: 123, location: 'somewhere')
  end

  let(:row) { Export::Csv::Events::Row.new(course) }

  subject { row }

  shared_context 'contactable' do
    def value(key)
      row.fetch(:"#{prefix}_#{key}")
    end

    describe 'without value' do
      specify 'keys' do
        contactable_keys.each { |key| value(key).should be_nil }
      end
    end
  end

  shared_examples_for 'contactable with value' do
    specify 'values' do
      value(:name).should eq contactable.to_s
      value(:email).should eq contactable.email
      value(:address).should eq contactable.address
      value(:zip_code).should eq contactable.zip_code
      value(:town).should eq contactable.town
      value(:phone_numbers).should eq contactable.phone_numbers.map(&:to_s).join(', ')
    end
  end

  context 'event attributes' do
    it { row.fetch(:kind).should eq 'Scharleiterkurs' }
    it { row.fetch(:state).should eq 'some state' }
    it { row.fetch(:number).should eq 123 }
    it { row.fetch(:location).should eq 'somewhere' }
    it { row.fetch(:description).should eq 'some description' }
    it { row.fetch(:group_names).should eq 'TopGroup' }
  end

  context 'contact person' do
    include_context 'contactable'

    let(:prefix) { :contact }

    context 'with contact' do
      let(:contactable) { person }
      before { course.contact = person }
      it_should_behave_like 'contactable with value'
    end
  end

  context 'leader' do
    include_context 'contactable'

    let(:prefix) { :leader }

    context 'with leader' do
      let(:participation) { Fabricate(:event_participation, event: course) }
      let!(:contactable) { Fabricate(Event::Role::Leader.name.to_sym, participation: participation).person }
      it_should_behave_like 'contactable with value'
    end
  end

  context 'dates' do
    let(:start_at) { Date.parse 'Sun, 09 Jun 2013' }
    let(:finish_at) { Date.parse 'Wed, 12 Jun 2013' }
    let(:date) { Fabricate(:event_date, event: course, start_at: start_at, finish_at: finish_at) }

    before { course.stub(dates: [date]) }

    it { row.fetch(:date_0_label).should eq 'Hauptanlass' }
    it { row.fetch(:date_0_duration).should eq '09.06.2013 - 12.06.2013' }

    it 'has keys for two more dates' do
      row.fetch(:date_1_label).should eq nil
      row.fetch(:date_2_label).should eq nil
    end
  end

end
