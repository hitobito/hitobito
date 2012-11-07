require 'spec_helper'

describe CensusEvaluation::StateController, type: :controller do
  
  render_views
  
  let(:ch)   { groups(:ch) }
  let(:be)   { groups(:be) }
  let(:bern) { groups(:bern) }
  let(:thun) { groups(:thun) }

  before { sign_in(people(:top_leader)) }
  
  describe "GET total" do
    before { get :total, id: ch.id }
    
    it { should render_template('total') }
  end
  
end
