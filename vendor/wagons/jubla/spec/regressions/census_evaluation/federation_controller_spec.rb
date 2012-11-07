require 'spec_helper'

describe CensusEvaluation::FederationController, type: :controller do
  
  render_views
  
  let(:ch)   { groups(:ch) }
  let(:zh)   { Fabricate(Group::State.name, name: 'Zurich', parent: ch) }

  before do
    zh #create
    sign_in(people(:top_leader))
  end
  
  describe "GET total" do
    before { get :total, id: ch.id }
    
    it { should render_template('total') }
  end
  
end
