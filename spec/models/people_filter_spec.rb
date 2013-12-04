# encoding: utf-8

#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

# == Schema Information
#
# Table name: people_filters
#
#  id         :integer          not null, primary key
#  name       :string(255)      not null
#  group_id   :integer
#  group_type :string(255)
#

require 'spec_helper'

describe PeopleFilter do

  it 'creates RoleTypes on assignment' do
    group = groups(:top_layer)
    filter = group.people_filters.new(name: 'Test')
    filter.role_types = ['Group::TopGroup::Leader', 'Group::TopGroup::Member']
    types = filter.related_role_types

    types.should have(2).items
    types.first.role_type.should == 'Group::TopGroup::Leader'

    filter.should be_valid
    expect { filter.save }.to change { RelatedRoleType.count }.by(2)
  end

end
