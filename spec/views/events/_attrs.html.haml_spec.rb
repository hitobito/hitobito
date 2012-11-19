# encoding: UTF-8
require 'spec_helper'

describe 'events/_attrs.html.haml' do
  
  let(:top_leader) { people(:top_leader) }
  
  before do
    assign(:event, event)
    assign(:group, event.groups.first)
    view.stub(action_name: 'events', current_user: top_leader, entry: event)
    controller.stub(current_user: top_leader)
    render
  end
  
  let(:dom) { Capybara::Node::Simple.new(rendered) }
  
  subject { dom }

  context "course" do
    let(:event) { EventDecorator.decorate(events(:top_course)) } 
    it "lists preconditions" do
      should have_content 'Vorbedingungen'
      should have_content 'Group Lead'
    end
  end

  context "event" do
    let(:event) { EventDecorator.decorate(events(:top_event)) } 
    it "lists preconditions" do
      should_not have_content 'Vorbedingungen'
    end
  end

end

