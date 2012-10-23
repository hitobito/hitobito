# encoding: UTF-8
require 'spec_helper'
describe "event/participations/_actions_show.html.haml" do
  let(:top_leader) { people(:top_leader) }
  let(:participation) { Fabricate(:event_participation, person: top_leader) }

  before do 
    view.stub(path_args: participation.event)
    view.stub(entry: participation) 
    controller.stub(current_user: top_leader)
  end

  subject { render; Capybara::Node::Simple.new(rendered).all('a').last }

  context "last button per default is the print button"do
    its([:href]) { should eq print_event_participation_path(participation.event, participation) }
    its(:text) { should eq " Drucken" } # space because of icon
  end

  context "renders edit contact data button when flash is present?" do
    before { controller.flash[:notice] = 'asdf' }
    its([:href]) { should eq edit_group_person_path(top_leader.groups.first, top_leader) }
    its(:text) { should eq " Kontaktdaten ändern" } # space because of icon
  end
end
