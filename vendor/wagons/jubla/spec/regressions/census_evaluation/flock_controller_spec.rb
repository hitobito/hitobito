require 'spec_helper'

describe CensusEvaluation::FlockController, type: :controller do
  
  render_views
  
  let(:ch)   { groups(:ch) }
  let(:be)   { groups(:be) }
  let(:bern) { groups(:bern) }

  before { sign_in(people(:top_leader)) }
  
  describe "GET total" do
    before { get :total, id: bern.id }
    
    it { should render_template('total') }
  end
  
end
