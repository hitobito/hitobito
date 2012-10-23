require 'spec_helper'

describe "application_market routes" do
  
  it do
    { :get => "/events/42/application_market" }.
    should route_to(
      :controller => "event/application_market",
      :action => 'index',
      :event_id => '42'
    )
  end
  
end
