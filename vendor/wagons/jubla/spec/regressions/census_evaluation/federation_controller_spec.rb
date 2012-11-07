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
    before { get :index, id: ch.id }
    
    it "renders correct templates" do
      should render_template('index')
      should render_template('_totals')
      should render_template('_details')
    end
  end
  
end
