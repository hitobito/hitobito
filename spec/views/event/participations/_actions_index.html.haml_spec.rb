require 'spec_helper'
describe "event/participations/_actions_index.html.haml" do 

  #subject { render; Capybara::Node::Simple.new(rendered).all('a').last }
  let(:event) { EventDecorator.decorate(Fabricate(:course)) }
  let(:top_leader) { people(:top_leader) }
  let(:add_role) { @dom.all('.dropdown-menu').first }
  let(:filter_role) { @dom.all('.dropdown-menu').last }

  before do
    assign(:event, event)
    assign(:group, event.groups.first)
    view.stub(parent: event)
    controller.stub(current_user: top_leader)
    render 
    @dom = Capybara::Node::Simple.new(@rendered) 
  end

  it "has dropdowns for adding and filtering" do
    add_role.should be_present
    filter_role.should be_present
  end
end
