require 'spec_helper'

describe CensusEvaluation::StateController do
  
  let(:ch)   { groups(:ch) }
  let(:be)   { groups(:be) }
  let(:bern) { groups(:bern) }
  let(:thun) { groups(:thun) }
  let(:muri) { groups(:muri) }
  
  before { sign_in(people(:top_leader)) }
  
  
  describe 'GET total' do
    
    before { get :total, id: be.id }
    
    it "assigns counts" do
      counts = assigns(:counts)
      counts.keys.should =~ [bern.id, thun.id]
      counts[bern.id].total.should == 12
      counts[thun.id].total.should == 7
    end
    
    it "assigns total" do
      assigns(:total).should be_kind_of(MemberCount)
    end
    
    it "assigns sub groups" do
      assigns(:sub_groups).should == [bern, muri, thun]
    end
    
  end
  
end
