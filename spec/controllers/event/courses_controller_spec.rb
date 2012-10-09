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

  context "GET index filter per group" do
    before { sign_in(people(:top_leader)) }

    it "defaults to toplevel group with courses in hiearchy" do
      get :index
      assigns(:group_id).should eq groups(:top_group).id
    end

    it "can be set via param, only if year is present" do
      get :index, year: 2010, group: groups(:top_layer).id
      assigns(:group_id).should eq groups(:top_layer).id
    end
  end

end
