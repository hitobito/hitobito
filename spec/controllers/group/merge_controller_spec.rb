# encoding: utf-8

#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require 'spec_helper'

describe Group::MergeController do

  context 'GET :select' do

    it "should redirect to group show if it's not possible to merge" do
      group = groups(:top_layer) # top_layer group has no sister groups

      sign_in(people(:top_leader))

      get :select, id: group.id

      flash[:alert].should =~ /Es sind keine gleichen Gruppen zum Fusionieren vorhanden/
      should redirect_to(group_path(group))
    end

  end

  # TODO test paths inside perform action
  context 'POST :perform' do
    it 'should redirect to form if params are missing' do
      group = groups(:bottom_layer_one)

      sign_in(people(:top_leader))

      post :perform, id: group.id, merger: { new_group_name: 'foo' }

      flash[:alert].should =~ /Bitte wähle eine Gruppe mit der fusioniert werden soll/
      should redirect_to(merge_group_path(group))

      post :perform, id: group.id, merger: { merge_group_id: '33' }

      flash[:alert].should =~ /Name für neue Gruppe muss definiert werden/
      should redirect_to(merge_group_path(group))
    end

    it "shouldn't be possible to merge groups without update rights in both groups" do
      group1 = groups(:bottom_layer_one)
      group2 = groups(:bottom_layer_two)
      group3 = Fabricate(Group::BottomLayer.name.to_s, name: 'Foo', parent_id: group1.parent_id)

      user = Fabricate(Group::BottomLayer::Leader.name.to_s, label: 'foo', group: group1).person
      Fabricate(Group::BottomLayer::Leader.name.to_s, label: 'foo', group: group3, person_id: user.id)

      sign_in(user)

      post :perform, id: group1.id, merger: { new_group_name: 'foo', merge_group_id: group2.id }

      flash[:alert].should =~ /Leider fehlt dir die Berechtigung um diese Gruppen zu fusionieren/
      should redirect_to(merge_group_path(group1))
    end

  end
end
