require 'spec_helper'

describe MemberCountsController, type: :controller do
  
  render_views
  
  let(:flock) { groups(:bern) }
  
  before { sign_in(people(:top_leader)) }
  
  describe "GET edit" do
    before { get :edit, group_id: flock.id, year: 2012 }
    
    it "should render template" do
      should render_template('edit')
    end
  end

end
