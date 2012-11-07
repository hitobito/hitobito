require 'spec_helper'

describe CensusEvaluation::FlockController, type: :controller do
  
  render_views
  
  let(:ch)   { groups(:ch) }
  let(:be)   { groups(:be) }
  let(:bern) { groups(:bern) }

  before { sign_in(people(:top_leader)) }
  
  describe "GET total" do
    before { get :index, id: bern.id }
    
    it "renders correct templates" do
      should render_template('index')
      should_not render_template('_totals')
      should render_template('_details')
    end
  end
  
end
