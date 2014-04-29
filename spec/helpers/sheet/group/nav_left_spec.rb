require 'spec_helper'

describe 'Sheet::Group::NavLeft' do

  let(:group) { groups(:bottom_group_one_one) }
  let(:sheet) { Sheet::Group.new(self, nil, group)}
  let(:nav) { Sheet::Group::NavLeft.new(sheet) }

  let(:request) { ActionController::TestRequest.new }

  let(:html) { nav.render }
  subject { Capybara::Node::Simple.new(html) }

  def can?(*args)
    true
  end

  it { should have_selector('li', count: 3) }
  it { should have_selector('ul', count: 2) }
  it 'has balanced li tags' do
    html.scan(/<li/).size.should eq html.scan(/<\/li>/).size
  end

  it 'has balanced li tags if last group is stacked' do
    Fabricate(Group::BottomGroup.sti_name.to_sym, parent: groups(:bottom_group_one_two))
    # 260 ms
     Group.benchmark do
    html.scan(/<li/).size.should eq html.scan(/<\/li>/).size
    end
  end

end
