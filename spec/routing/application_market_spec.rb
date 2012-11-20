require 'spec_helper'

describe "application_market routes" do
  
  it do
    { :get => "/groups/1/events/42/application_market" }.
    should route_to(
      :controller => "event/application_market",
      :action => 'index',
      :event_id => '42',
      :group_id => '1'
    )
  end
  
end
