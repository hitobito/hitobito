require 'spec_helper'

describe Export::CsvPeople::ParticipationsAddress do
  
  let(:person) { people(:top_leader) }
  let(:participation) { Fabricate(:event_participation, person: person, event: events(:top_course)) }
  let(:list) { [participation] }
  let(:people_list) { Export::CsvPeople::ParticipationsAddress.new(list) }

  subject { people_list }

  context "address data" do
    its([:first_name]) { should eq 'Vorname' }
    its([:town]) { should eq 'Ort' }
  end
end
