# encoding: UTF-8
require 'spec_helper_request'

describe "Simple" do

  it "implicit capybara server", js: true do
    sign_in 'top_leader@example.com', 'foobar'
    visit root_path
    page.body.should include("TopGroup")
  end
  
end
