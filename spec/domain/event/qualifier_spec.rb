require 'spec_helper'

describe Event::Qualifier do
    
  let(:kind) { event_kinds(:slk) }
  
  let(:course) do
    event = Fabricate(:course, kind: kind)
    event.dates.create!(start_at: Date.new(2012, 10, 02), finish_at: quali_date)
    event
  end
  
  let(:participant) do
    participation = Fabricate(:event_participation, event: course)
    Fabricate(Event::Course::Role::Participant.name.to_sym, participation: participation)
    participation
  end
  
  let(:person) { participant.person }
  let(:quali_date) { Date.new(2012, 10, 20) }
  
  subject { Event::Qualifier.new(participant) }
  
  context "spec preconditions" do
    it "event kind has one qualification kind" do
      course.kind.qualification_kinds.should == [qualification_kinds(:sl)]
    end
    it "event kind has one prolongation kind" do
      course.kind.prolongations.should == [qualification_kinds(:gl)]
    end
  end
  
  describe "#qualified?" do
    before do
      course.stub(:qualification_date).and_return(quali_date)
    end
    
    context "event kind with one qualification kind" do
      context "without qualifications" do
        it { should_not be_qualified }
        its(:qualifications) { should have(0).items }
      end
      
      context "with old qualification" do
        before do
          Fabricate(:qualification, person: person, qualification_kind: qualification_kinds(:sl), start_at: Date.new(2010, 04, 20))
        end
        
        it { should_not be_qualified }
        its(:qualifications) { should have(0).items }
      end
      
      context "with event qualification" do
        before do
          Fabricate(:qualification, person: person, qualification_kind: qualification_kinds(:sl), start_at: quali_date)
        end
        
        it { should be_qualified }
        its(:qualifications) { should have(1).items }
      end
    end
    
    context "event kind with multiple qualification kinds" do
      let(:other_kind) { Fabricate(:qualification_kind) }
      before do
        course.kind.qualification_kinds << other_kind
      end
      
      context "without qualifications" do
        it { should_not be_qualified }
        its(:qualifications) { should have(0).items }
      end
      
      context "with one qualification" do
        before do
          Fabricate(:qualification, person: person, qualification_kind: qualification_kinds(:sl), start_at: quali_date)
        end
        
        it { should_not be_qualified }
        its(:qualifications) { should have(1).item }

      end
      
      context "with event qualification" do
        before do
          Fabricate(:qualification, person: person, qualification_kind: qualification_kinds(:sl), start_at: quali_date)
          Fabricate(:qualification, person: person, qualification_kind: other_kind, start_at: quali_date)
        end
        
        it { should be_qualified }
        its(:qualifications) { should have(2).items }
      end
    end
    
    context "event kind without qualification kinds" do
      let(:other_kind) { Fabricate(:qualification_kind) }
      before do
        course.kind.qualification_kinds.clear
      end
      
      context "without qualifications" do
        it { should be_qualified }
        its(:qualifications) { should have(0).items }
      end
      
      context "with qualification" do
        before do
          Fabricate(:qualification, person: person, qualification_kind: qualification_kinds(:sl), start_at: quali_date)
        end
        
        it { should be_qualified }
        its(:qualifications) { should have(0).items }
      end
    end
    
    context "with qualification and prolongation kind" do
      context "without existing qualifications" do
        it { should_not be_qualified }
      end
      
      context "with old qualification and prolongation" do
        before do
          Fabricate(:qualification, person: person, qualification_kind: qualification_kinds(:sl), start_at: Date.new(2008, 2, 23))
          
          Fabricate(:qualification, person: person, qualification_kind: qualification_kinds(:gl), start_at: quali_date - 1.year)
          Fabricate(:qualification, person: person, qualification_kind: qualification_kinds(:gl), start_at: quali_date)
        end
        it { should_not be_qualified }
      end
      
      context "only with existing qualification" do
        before { Fabricate(:qualification, person: person, qualification_kind: qualification_kinds(:sl), start_at: quali_date) }
        it { should be_qualified }
      end
      
      context "with existing qualification and existing prolongation" do
        before do
          Fabricate(:qualification, person: person, qualification_kind: qualification_kinds(:sl), start_at: quali_date)
          Fabricate(:qualification, person: person, qualification_kind: qualification_kinds(:gl), start_at: quali_date - 1.year)
        end
        it { should_not be_qualified }
      end
      
      context "with existing qualification and prolongation" do
        before do
          Fabricate(:qualification, person: person, qualification_kind: qualification_kinds(:gl), start_at: Date.new(2008, 2, 23))
          
          Fabricate(:qualification, person: person, qualification_kind: qualification_kinds(:gl), start_at: quali_date - 1.year)
          Fabricate(:qualification, person: person, qualification_kind: qualification_kinds(:gl), start_at: quali_date)
          
          Fabricate(:qualification, person: person, qualification_kind: qualification_kinds(:sl), start_at: quali_date)
        end
        it { should be_qualified }
      end
    end
    
    context "only with prolongation kind" do
      let(:kind) { event_kinds(:fk) }
      
      context "without existing qualifications" do
        it { should be_qualified }
      end
      
      context "with old qualification" do
        before do
          Fabricate(:qualification, person: person, qualification_kind: qualification_kinds(:sl), start_at: Date.new(2008, 2, 23))
        end
        
        it { should be_qualified }
      end
      
      context "with existing, but not prolonged qualification" do
        before do
          Fabricate(:qualification, person: person, qualification_kind: qualification_kinds(:sl), start_at: quali_date - 1.year)
        end
        
        it { should_not be_qualified }
      end
      
      context "with one existing prolongation" do
        before do
          Fabricate(:qualification, person: person, qualification_kind: qualification_kinds(:sl), start_at: quali_date - 1.year)
          Fabricate(:qualification, person: person, qualification_kind: qualification_kinds(:sl), start_at: quali_date)
        end
        
        it { should be_qualified }
      end
      
      context "with two existing prolongation" do
        before do
          Fabricate(:qualification, person: person, qualification_kind: qualification_kinds(:sl), start_at: quali_date - 1.year)
          Fabricate(:qualification, person: person, qualification_kind: qualification_kinds(:sl), start_at: quali_date)
          
          Fabricate(:qualification, person: person, qualification_kind: qualification_kinds(:gl), start_at: quali_date - 1.year)
          Fabricate(:qualification, person: person, qualification_kind: qualification_kinds(:gl), start_at: quali_date)
        end
        
        it { should be_qualified }
      end
      
      context "with old qualification and existing prolongation" do
        before do
          Fabricate(:qualification, person: person, qualification_kind: qualification_kinds(:gl), start_at: Date.new(2008, 2, 23))
          
          Fabricate(:qualification, person: person, qualification_kind: qualification_kinds(:gl), start_at: quali_date - 1.year)
          Fabricate(:qualification, person: person, qualification_kind: qualification_kinds(:gl), start_at: quali_date)
          
          Fabricate(:qualification, person: person, qualification_kind: qualification_kinds(:sl), start_at: quali_date - 1.year)
          Fabricate(:qualification, person: person, qualification_kind: qualification_kinds(:sl), start_at: quali_date)
        end
        
        it { should be_qualified }
      end
    end
  end
  
  describe '#issue' do
    context "with qualification and prolongation kind" do
      context "without existing qualifications" do
        before { subject.issue }
        
        its(:qualifications) { should have(1).item }
      end
      
      context "with existing qualification" do
        before { Fabricate(:qualification, person: person, qualification_kind: qualification_kinds(:sl), start_at: quali_date) }
        
        it "does not create additional qualification" do
          expect { subject.issue }.not_to change { person.reload.qualifications.count }
        end
      end
      
      context "with existing prolongation" do
        before { Fabricate(:qualification, person: person, qualification_kind: qualification_kinds(:gl), start_at: Date.new(2011, 9, 15)) }
        
        it "creates qualification and prolongation" do
          expect { subject.issue }.to change { person.reload.qualifications.count }.by(2)
          
          qualis = person.qualifications.where(start_at: quali_date)
          qualis.should have(2).items
          qualis.detect {|q| q.qualification_kind == qualification_kinds(:gl) }.should be_present
          qualis.detect {|q| q.qualification_kind == qualification_kinds(:sl) }.should be_present
        end
      end
      
      context "with expired prolongation" do
        before { Fabricate(:qualification, person: person, qualification_kind: qualification_kinds(:gl), start_at: Date.new(2005, 9, 15)) }
        
        it "creates only qualification" do
          expect { subject.issue }.to change { person.reload.qualifications.count }.by(1)
          
          qualis = person.qualifications.where(start_at: quali_date)
          qualis.should have(1).item
          qualis.detect {|q| q.qualification_kind == qualification_kinds(:gl) }.should be_blank
          qualis.detect {|q| q.qualification_kind == qualification_kinds(:sl) }.should be_present
        end
      end
    end
    
    
    context "without qualification kind" do
      let(:kind) { event_kinds(:fk) }
      
      context "without existing qualifications" do
        before { subject.issue }
        
        its(:qualifications) { should have(0).item }
      end
      
      context "with existing prolongation" do
        before { Fabricate(:qualification, person: person, qualification_kind: qualification_kinds(:gl), start_at: Date.new(2011, 9, 15)) }
        
        it "creates prolongation" do
          expect { subject.issue }.to change { person.reload.qualifications.count }.by(1)
          
          qualis = person.qualifications.where(start_at: quali_date)
          qualis.should have(1).items
          qualis.detect {|q| q.qualification_kind == qualification_kinds(:gl) }.should be_present
          qualis.first.origin.should eq course.to_s
        end
      end
      
      context "with multiple existing prolongation" do
        before do
          Fabricate(:qualification, person: person, qualification_kind: qualification_kinds(:gl), start_at: Date.new(2011, 9, 15))
          Fabricate(:qualification, person: person, qualification_kind: qualification_kinds(:gl), start_at: Date.new(2010, 5, 5))
          Fabricate(:qualification, person: person, qualification_kind: qualification_kinds(:sl), start_at: Date.new(2011, 3, 8))
        end
        
        it "creates prolongations" do
          expect { subject.issue }.to change { person.reload.qualifications.count }.by(2)
          
          qualis = person.qualifications.where(start_at: quali_date)
          qualis.should have(2).items
          qualis.detect {|q| q.qualification_kind == qualification_kinds(:gl) }.should be_present
          qualis.detect {|q| q.qualification_kind == qualification_kinds(:sl) }.should be_present
        end
      end
      
      context "with expired prolongation" do
        before { Fabricate(:qualification, person: person, qualification_kind: qualification_kinds(:gl), start_at: Date.new(2005, 9, 15)) }
        
        it "creates nothing" do
          expect { subject.issue }.not_to change { person.reload.qualifications.count }
          
          qualis = person.qualifications.where(start_at: quali_date)
          qualis.should be_empty
        end
      end
    end
    
  end
  
  describe '#revoke' do
    context "with qualification and prolongation kind" do
      context "without existing qualifications" do
        before { subject.revoke }
        
        its(:qualifications) { should be_empty }
      end
      
      context "with existing qualification" do
        before { Fabricate(:qualification, person: person, qualification_kind: qualification_kinds(:sl), start_at: quali_date) }
        
        it "removes qualification" do
          expect { subject.revoke }.to change { person.reload.qualifications.count }.by(-1)
        end
      end
      
      context "with existing qualification and prolongation" do
        before do
          Fabricate(:qualification, person: person, qualification_kind: qualification_kinds(:gl), start_at: quali_date)
          Fabricate(:qualification, person: person, qualification_kind: qualification_kinds(:sl), start_at: quali_date)
        end
        
        it "removes both" do
          expect { subject.revoke }.to change { person.reload.qualifications.count }.by(-2)
        end
      end
      
      context "with old qualification" do
        before { Fabricate(:qualification, person: person, qualification_kind: qualification_kinds(:gl), start_at: Date.new(2005, 9, 15)) }
        
        it "creates only qualification" do
          expect { subject.revoke }.not_to change { person.reload.qualifications.count }
        end
      end
    end
  end
 
end
