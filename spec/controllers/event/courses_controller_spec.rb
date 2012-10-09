require 'spec_helper'

describe Event::CoursesController do

  before { sign_in(people(:top_leader)) }
   
  context "GET index filters by year" do
    let(:year) { Date.today.year }
    let(:year_range) { (year-2...year+3) }

    it "defaults to current year" do
      get :index
      assigns(:year).should eq year
      assigns(:year_range).should eq year_range
    end

    it "reads year from params, populates vars"do
      get :index, year: 2010
      assigns(:year).should eq 2010
      assigns(:year_range).should eq year_range
    end

    it "years has a reasonable limits" do
      get :index, year: 1995
      assigns(:year).should eq year
      assigns(:year_range).should eq year_range
    end


  end

end
