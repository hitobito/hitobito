require "spec_helper"

describe "groups/show.html.haml" do

  let(:group) { groups(:top_layer) }
  let(:entry) { GroupExhibit.new(group, view) }
  let(:subject) { Capybara::Node::Simple.new(@rendered) }

  it "requires @group to render" do
    view.stub(entry: entry, path_args: group, can?: false) 
    expect { render }.to raise_error /No route matches/
  end

  it "requires entry to render" do
    assign(:group, entry)
    expect { render }.to raise_error /undefined local variable or method `entry'/
  end

end
