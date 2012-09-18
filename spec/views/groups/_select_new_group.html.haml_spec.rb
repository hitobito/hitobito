require 'spec_helper'
describe "groups/_select_new_group.html.haml" do

  let(:group) { groups(:top_layer) }
  let(:subject) { Capybara::Node::Simple.new(@rendered) }

  before { view.stub(entry: GroupExhibit.new(group, view), can?: false) }

  it "does not render new group dropdown" do
    render partial: 'groups/select_new_group'
    should_not have_selector 'ul.dropdown-menu'
    should_not have_content "Neue Gruppe erstellen"
  end

  it "renders dropdown when if we can? :new, Group" do
    view.should_receive(:can?).with(:new, Group).and_return(true)
    render partial: 'groups/select_new_group'
    should have_content "Neue Gruppe erstellen"
    should have_selector 'ul.dropdown-menu'
    should have_selector group_link(parent_id: group.id, type: 'Group::TopGroup')
    should have_selector group_link(parent_id: group.id, type: 'Group::BottomLayer')
  end

  def group_link(hash)
    "a[href='#{new_group_path(group: hash)}']"
  end

end
