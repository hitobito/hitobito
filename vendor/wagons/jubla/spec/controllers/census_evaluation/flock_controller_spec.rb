require 'spec_helper'

describe CensusEvaluation::FlockController do
  
  let(:ch)   { groups(:ch) }
  let(:be)   { groups(:be) }
  let(:bern) { groups(:bern) }

  
  before { sign_in(people(:top_leader)) }
  
  
  describe 'GET total' do
    
    before { get :total, id: bern.id }
    
    it "assigns counts" do
      assigns(:counts).should be_blank
    end
    
    it "assigns total" do
      total = assigns(:total)
      total.should be_kind_of(MemberCount)
      total.total.should == 12
    end
    
    it "assigns sub groups" do
      assigns(:sub_groups).should == []
    end
    
  end
  
end
