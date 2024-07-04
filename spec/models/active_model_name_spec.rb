#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "spec_helper"

describe ActiveModel::Name do
  it "has regular route keys" do
    Event.model_name.route_key == "events"
  end

  it "has route keys from sti base class" do
    expect(Group::TopLayer.model_name.route_key).to eq("groups")
  end
  it "does not have demodulized route keys by default" do
    expect(Event::Kind.model_name.route_key).to eq("event_kinds")
  end

  it "has demodulized route keys if requested" do
    expect(Event::Application.model_name.route_key).to eq("applications")
  end
end
