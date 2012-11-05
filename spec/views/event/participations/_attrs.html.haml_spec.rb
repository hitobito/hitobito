# encoding: UTF-8
require 'spec_helper'

describe "event/participations/_attrs.html.haml" do
  let(:top_leader) { people(:top_leader) }
  let(:participation) { Fabricate(:event_participation, person: top_leader) }

  before do 
    view.stub(path_args: participation.event)
    view.stub(entry: participation) 
    view.stub(current_user: top_leader)
  end

  subject { render; Capybara::Node::Simple.new(rendered).all('a').last }

end