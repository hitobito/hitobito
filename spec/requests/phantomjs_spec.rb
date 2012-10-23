# encoding: UTF-8
require 'spec_helper'
describe "PhantomJS" do
  include RequestHelpers 

  let(:person) { people(:top_leader) }
  let(:group) { groups(:bottom_layer_one)}
  specify do
    person.valid_password?('foobar').should be_true
  end

  it "authenticates via basic auth" do
    set_basic_auth person.email, "foobar"
    visit group_path(group)
    page.body.should include('Neue Gruppe erstellen')
  end

  pending "rendres asstes", js: true do
    visit root_url
  end
 
  #it "renders homepage via session", js: true do
    #set_basic_auth person.email, "foobar"
    #visit group_path(group)
    #puts page.body
    #page.find('.dropdown-menu').should_not be_visible
    #page.body.should include('Neue Gruppe erstellen')
    #puts page.body
  #end
  
end

