require 'spec_helper'
describe Export::Courses::Row do

  let(:max_dates) { 3 }
  let(:contactable_keys) { [:name, :address, :zip_code, :town, :email, :phone_numbers] }
  let(:person) { Fabricate(:person_with_address_and_phone) }
  let(:course) { Fabricate(:course, state: :application_closed, groups: [groups(:top_group)],
                                    description: 'some description', number: 123, location: 'somewhere') }

  let(:list)  { OpenStruct.new(max_dates: 3, contactable_keys: contactable_keys) }

  let(:row) { Export::Courses::Row.new(course,list) }

  subject { OpenStruct.new(row.hash) }

  shared_context "contactable" do
    def value(key)
      row.hash.fetch(:"#{prefix}_#{key}")
    end

    describe "without value" do
      specify "keys" do
        contactable_keys.each { |key| row.hash.should have_key(:"#{prefix}_#{key}") }
      end
    end
  end

  shared_examples_for "contactable with value" do
    specify "values" do
      value(:name).should eq contactable.to_s
      value(:email).should eq contactable.email
      value(:address).should eq contactable.address
      value(:zip_code).should eq contactable.zip_code
      value(:town).should eq contactable.town
      value(:phone_numbers).should eq contactable.phone_numbers.map(&:to_s).join(', ')
    end
  end

  context "event attributes" do
    its(:kind)   { should eq "Scharleiterkurs" }
    its(:state)   { should =~  /translation missing/ }
    its(:number) { should eq 123 }
    its(:location)   { should eq "somewhere" }
    its(:description)   { should eq "some description" }
    its(:group_names) { should eq "TopGroup" }
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

    before { course.stub(dates: [date]) }

    its(:date_0_label) { should eq 'Hauptanlass' }
    its(:date_0_duration) { should eq '09.06.2013 - 12.06.2013' }

    it "has keys for two more dates" do
      row.hash.should have_key(:date_1_label)
      row.hash.should have_key(:date_2_label)
    end
  end

end
