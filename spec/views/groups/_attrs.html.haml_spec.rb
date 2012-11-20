require 'spec_helper'
describe 'groups/_attrs.html.haml' do

  let(:group) { groups(:top_layer) }

  let(:dom) { Capybara::Node::Simple.new(@rendered)  } 

  before do
    assign(:group, group)
    assign(:sub_groups, {'Gruppen' => [groups(:bottom_layer_one)], 
                         'Untergruppen' => [groups(:top_group)]})
    view.stub(current_user: current_user)
    controller.stub(current_user: current_user)
    view.stub(entry: GroupDecorator.decorate(group))
    render 
  end

  context "viewed by top leader" do
    let(:current_user) { people(:top_leader) } 
    let(:sections) { dom.all('aside section') } 

    it "shows layer and subgroups in different sections" do
      sections.first.should have_content 'Gruppen'
      sections.last.should have_content 'Untergruppen'
    end
  end
  
end

