# encoding: UTF-8
require 'spec_helper'
describe 'event/lists/events.html.haml' do
  let(:top_leader) { people(:top_leader) }
  before do
    assign(:events, EventDecorator.decorate(events))
    view.stub(action_name: 'events', current_user: top_leader)
    controller.stub(current_user: top_leader)

  end
  let(:dom) { Capybara::Node::Simple.new(rendered) }
  subject { dom }

  context "grouping" do
    let(:events) { [create_event(start_at: Time.zone.parse("2012-10-30")),
                    create_event(start_at: Time.zone.parse("2012-11-1"))] } 
    it "groups by month" do
      render
      should have_content 'Oktober, 2012'
      should have_content 'November, 2012'
    end
  end

  context "application" do
    let(:events) { [create_event(start_at: 1.day.from_now)] }
    let(:link) { dom.all('a').last }
    it "contains apply button for future events" do
      events.first.application_possible?.should eq true
      render
      link.text.should eq 'Anmelden'
      link[:href].should eq new_event_participation_path(events.first)
    end
  end

  def create_event(hash={})
    hash = ({type: :event, group: :top_group}).merge(hash)
    event = Fabricate(hash[:type], group: groups(hash[:group]))
    set_start_dates(event, hash[:start_at])
    event
  end
  
end

