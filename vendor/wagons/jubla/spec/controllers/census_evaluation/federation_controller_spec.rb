require 'spec_helper'

describe CensusEvaluation::FederationController do
  
  let(:ch)   { groups(:ch) }
  let(:be)   { groups(:be) }
  let(:no)   { groups(:no) }
  let(:zh)   { Fabricate(Group::State.name, name: 'Zurich', parent: ch) }

  before do
    zh #create
    
    sign_in(people(:top_leader))
  end
  
  
  describe 'GET total' do
    
    before { get :total, id: ch.id }
    
    it "assigns counts" do
      counts = assigns(:counts)
      counts.keys.should =~ [be.id, no.id]
      counts[be.id].total.should == 19
      counts[no.id].total.should == 9
    end
    
    it "assigns total" do
      assigns(:total).should be_kind_of(MemberCount)
    end
    
    it "assigns sub groups" do
      assigns(:sub_groups).should == [be, no, zh]
    end
    
    it "assigns flocks" do
      assigns(:flocks).should == {
        be.id => {confirmed: 2, total: 3},
        no.id => {confirmed: 1, total: 2},
        zh.id => {confirmed: 0, total: 0},
      }.with_indifferent_access
    end
  end
  
end
