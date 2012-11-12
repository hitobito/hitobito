require 'spec_helper'

describe CensusEvaluation::StateController, type: :controller do
  
  render_views
  
  let(:ch)   { groups(:ch) }
  let(:be)   { groups(:be) }
  let(:bern) { groups(:bern) }
  let(:thun) { groups(:thun) }

  before { sign_in(people(:top_leader)) }
  
  describe "GET total" do
    before { get :index, id: be.id }
    
    it "renders correct templates" do
      should render_template('index')
      should render_template('_totals')
      should render_template('_details')
    end
  end
  
end
