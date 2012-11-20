require 'spec_helper'
describe "event/participations/_actions_index.html.haml" do 

  #subject { render; Capybara::Node::Simple.new(rendered).all('a').last }
  let(:event) { EventDecorator.decorate(Fabricate(:course)) }
  let(:top_leader) { people(:top_leader) }
  let(:application) { Fabricate(:event_application, priority_1: event)}
  let(:participation) { Fabricate(:event_participation, application: application, person: top_leader, event: event) }
  let(:add_role) { @dom.all('.dropdown-menu').first }
  let(:filter_role) { @dom.all('.dropdown-menu').last }

  before do
    assign(:event, event)
    assign(:group, event.groups.first)
    view.stub(parent: event)
    view.stub(entry: participation)
    controller.stub(current_user: top_leader)
    render 
    @dom = Capybara::Node::Simple.new(@rendered) 
  end

  it "has dropdowns for adding and filtering" do
    add_role.should be_present
    filter_role.should be_present
  end
end
