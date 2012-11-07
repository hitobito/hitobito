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
    
    before { get :index, id: ch.id }
    
    it "assigns counts" do
      counts = assigns(:group_counts)
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
     
     it "assigns details" do
      details = assigns(:details).to_a
      details.should have(5).items
      
      details[0].born_in.should == 1984
      details[1].born_in.should == 1985
      details[2].born_in.should == 1988
      details[3].born_in.should == 1997
      details[4].born_in.should == 1999
    end
    
    it "assigns year" do
      assigns(:year).should == Census.last.year
    end
  end
  
end
