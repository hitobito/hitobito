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
  
end
