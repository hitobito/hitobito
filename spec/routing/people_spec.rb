require 'spec_helper'

describe "people routes" do
  
  it do
    { :get => "/people/42" }.
    should route_to(
      :controller => "people",
      :action => 'show',
      :id => '42'
    )
  end
  
end
