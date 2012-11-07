require 'spec_helper'

describe CensusEvaluation::FlockController, type: :controller do
  
  render_views
  
  let(:ch)   { groups(:ch) }
  let(:be)   { groups(:be) }
  let(:bern) { groups(:bern) }

  before do
    Census.create!(year: 2012, start_at: Date.new(2012,8,1))
    
    create_count(bern, be, 1985, leader_m: 3, leader_f: 1)
    create_count(bern, be, 1988, leader_f: 1, child_m: 1)
    create_count(bern, be, 1997, child_m: 2, child_f: 4)
    
    sign_in(people(:top_leader))
  end
  
  describe "GET total" do
    before { get :total, id: bern.id }
    
    it { should render_template('total') }
  end
  
  def create_count(flock, state, born_in, attrs = {})
    count = MemberCount.new
    count.flock_id = flock.id
    count.state_id = state.id
    count.year = 2012
    count.born_in = born_in
    count.attributes = attrs
    count.save!
  end
end
