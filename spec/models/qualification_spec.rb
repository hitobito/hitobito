# == Schema Information
#
# Table name: qualifications
#
#  id                    :integer          not null, primary key
#  person_id             :integer          not null
#  qualification_kind_id :integer          not null
#  start_at              :date             not null
#  finish_at             :date
#

require 'spec_helper'

describe Qualification do
  
  let(:qualification) { Fabricate(:qualification) }
  let(:person) { qualification.person }

  it "includes qualification kind and finish_at in to_s" do
    quali = Fabricate(:qualification, qualification_kind: qualification_kinds(:sl), 
                      start_at: Date.parse("2011-3-3").to_date)
    quali.to_s.should eq "Super Lead (bis 31.12.2013)"
  end
  
  describe "#set_finish_at" do
    let(:date) { Date.today }
    
    it "set current end of year if validity is 0" do
      quali = build_qualification(0, date)
      quali.valid?
      
      quali.finish_at.should == date.end_of_year
    end
    
    it "set respective end of year if validity is 2" do
      quali = build_qualification(2, date)
      quali.valid?
      
      quali.finish_at.should == (date + 2.years).end_of_year
    end
    
    it "does not set year if validity is nil" do
      quali = build_qualification(nil, date)
      quali.valid?
      
      quali.finish_at.should be_nil
    end
    
    it "does not set year if start_at is nil" do
      quali = build_qualification(2, nil)
      quali.valid?
      
      quali.finish_at.should be_nil
    end
    
    def build_qualification(validity, start_at)
      kind = Fabricate(:qualification_kind, validity: validity)
      Qualification.new(qualification_kind: kind, start_at: start_at)
    end
  end
  
  describe "#active" do
    subject { qualification }
    it { should be_active}
  end
  
  describe ".active" do
    subject { person.reload.qualifications.active }
    
    it "contains from today" do
      q = Fabricate(:qualification, person: person, start_at: Date.today)
      q.should be_active
      should include(q)
    end
    
    it "does contain until this year" do
      q = Fabricate(:qualification, person: person, start_at: Date.today - 2.years)
      q.should be_active
      should include(q)
    end
    
    it "does not contain past" do
      q = Fabricate(:qualification, person: person, start_at: Date.today - 5.years)
      q.should_not be_active
      should_not include(q)
    end
    
    it "does not contain future" do
      q = Fabricate(:qualification, person: person, start_at: Date.today + 1.day)
      q.should_not be_active
      should_not include(q)
    end
  end
  
end
