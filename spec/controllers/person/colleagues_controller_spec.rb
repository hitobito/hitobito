# encoding: utf-8

#  Copyright (c) 2017, Dachverband Schweizer Jugendparlamente. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "spec_helper"

describe Person::ColleaguesController do
  let(:top_leader) { people(:top_leader) }

  before { sign_in(top_leader) }

  describe "GET #index" do
    it "returns ordered colleagues" do
      c1 = create_person(Group::TopGroup::LocalGuide, :top_group)
      c2 = create_person(Group::BottomLayer::Leader, :bottom_layer_one)
      c3 = create_person(Group::BottomGroup::Leader, :bottom_group_one_one)
      c4 = create_person(Group::BottomGroup::Member, :bottom_group_one_one)

      get :index, params: {group_id: groups(:top_group).id, id: c1.id, sort: :roles}

      expect(assigns(:colleagues)).to eq([c1, c2, c3, c4])
    end

    it "contains nobody if persons company_name is blank" do
      p = Fabricate(Group::TopGroup::LocalGuide.name.to_sym, group: groups(:top_group)).person

      get :index, params: {group_id: groups(:top_group).id, id: p.id}

      expect(assigns(:colleagues)).to eq([])
    end
  end

  def create_person(role, group)
    Fabricate(role.name.to_sym,
      group: groups(group),
      person: Fabricate(:person, company_name: "Foo Inc.")).person
  end
end
