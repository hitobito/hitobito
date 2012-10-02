require 'spec_helper'

describe Event::CoursesController do

  before { sign_in(people(:top_leader)) }
   
  context "GET index filters by year" do
    let(:year) { Date.today.year }

    it "reads year from params, populates vars"do
      get :index, year: 2010
      assigns(:year).should eq 2010
      assigns(:years).should eq (2007...2013)
    end


    it "defaults to current year" do
      get :index
      assigns(:year).should eq Date.today.year
    end
  end

end
