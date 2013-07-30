# encoding: utf-8

#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require 'spec_helper'
describe RoleDecorator, :draper_with_helpers do

  let(:role) { roles(:top_leader)}
  let(:decorator) {  RoleDecorator.new(role) }
  subject { decorator }

  its(:flash_info) { should eq "<i>Leader</i> für <i>Top Leader</i> in <i>TopGroup</i>" }

  describe "possible_role_collection_select" do
    subject { Capybara::Node::Simple.new(decorator.possible_role_collection_select) }
    it "has select and two options" do
      subject.find('select')[:name].should eq "role[type]"
      subject.all('option')[0][:value].should eq "Group::TopGroup::Leader"
      subject.all('option')[1][:value].should eq "Group::TopGroup::Secretary"
      subject.all('option')[2][:value].should eq "Group::TopGroup::Member"
    end

    it "preselects option" do
      role.type = "Group::TopGroup::Member"
      subject.all('option')[2][:selected].should eq "selected"
    end
  end
end
