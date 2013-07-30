# encoding: utf-8

#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

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
