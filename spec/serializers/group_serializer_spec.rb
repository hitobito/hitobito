# encoding: utf-8

#  Copyright (c) 2014, CEVI Regionalverband ZH-SH-GL. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require 'spec_helper'

describe GroupSerializer do

  let(:group) { groups(:top_group).decorate }
  let(:controller) { double().as_null_object }

  let(:serializer) { GroupSerializer.new(group, controller: controller)}
  let(:hash) { serializer.to_hash }

  subject { hash[:groups].first }

  it 'has different entities' do
    links = subject[:links]
    links[:parent].should eq(group.parent_id.to_s)
    links.should_not have_key(:children)
    links[:layer_group].should eq(group.parent_id.to_s)
    links[:hierarchies].should have(2).items
  end
end