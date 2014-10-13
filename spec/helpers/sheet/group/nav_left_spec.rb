# encoding: utf-8

#  Copyright (c) 2012-2014, Pfadibewegung Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require 'spec_helper'

describe 'Sheet::Group::NavLeft' do

  let(:group) { groups(:bottom_group_one_one) }
  let(:sheet) { Sheet::Group.new(self, nil, group) }
  let(:nav)   { Sheet::Group::NavLeft.new(sheet) }

  let(:request) { ActionController::TestRequest.new }

  let(:html) { nav.render }
  subject { Capybara::Node::Simple.new(html) }

  def can?(*_args)
    true
  end

  it { should have_selector('li', count: 3) }

  it { should have_selector('ul', count: 2) }

  it 'has balanced li tags' do
    html.scan(/<li/).size.should eq html.scan(/<\/li>/).size
  end

  it 'has balanced li tags if last group is stacked' do
    Fabricate(Group::BottomGroup.sti_name.to_sym, parent: groups(:bottom_group_one_two))
    html.scan(/<li/).size.should eq html.scan(/<\/li>/).size
  end

end
