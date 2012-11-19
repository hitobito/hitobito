# encoding: UTF-8
require 'spec_helper'

describe "event/participations/_actions_show.html.haml" do
  let(:participant) { people(:top_leader )}
  let(:participation) { Fabricate(:event_participation, person: participant) }
  let(:user) { participant }
  let(:event) { participation.event }
  let(:group) { event.groups.first}

  before do 
    view.stub(path_args: [group, event])
    view.stub(entry: participation) 
    controller.stub(current_user: user)
    view.stub(:current_user) {user}
    assign(:event, event)
    assign(:group, group)
  end
  

  context "last button" do
    subject { Capybara::Node::Simple.new(rendered).all('a').last }
  
    context "last button per default is the print button"do
      before { render }
    
      its([:href]) { should eq print_group_event_participation_path(group, event, participation) }
      its(:text) { should eq " Drucken" } # space because of icon
    end
  
    context "renders edit contact data button when flash is present?" do
      before { controller.flash[:notice] = 'asdf' }
      before { render }
      its([:href]) { should eq edit_group_person_path(participant.groups.first, participant) }
      its(:text) { should eq " Kontaktdaten ändern" } # space because of icon
    end
  end
  
end
