# encoding: UTF-8
require 'spec_helper'
describe 'event/lists/events.html.haml' do

  before do
    events = [create_event(start_at: Time.zone.parse("2012-10-30")),
              create_event(start_at: Time.zone.parse("2012-11-1"))]
    assign(:events, EventDecorator.decorate(events))
    view.stub(action_name: 'events')
  end
  subject { Capybara::Node::Simple.new(rendered) }

  it "groups by month" do
    render
    should have_content 'Oktober, 2012'
    should have_content 'November, 2012'
  end


  def create_event(hash={})
    hash = ({type: :event, group: :top_group}).merge(hash)
    event = Fabricate(hash[:type], group: groups(hash[:group]))
    event.dates.create(start_at: hash[:start_at]) if hash[:start_at]
    event
  end
  
end

