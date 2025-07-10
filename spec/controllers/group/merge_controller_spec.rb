#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "spec_helper"

describe Group::MergeController do
  context "GET :select" do
    it "should redirect to group show if it's not possible to merge" do
      group = groups(:top_layer) # top_layer group has no sister groups

      sign_in(people(:top_leader))

      get :select, params: {id: group.id}

      expect(flash[:alert]).to match(/Es sind keine gleichen Gruppen zum Fusionieren vorhanden/)
      is_expected.to redirect_to(group_path(group))
    end

    it "should not offer deleted sibling groups" do
      group = groups(:bottom_layer_one)
      groups(:bottom_layer_two).update_attribute(:deleted_at, 1.day.ago)

      sign_in(people(:top_leader))

      get :select, params: {id: group.id}

      expect(flash[:alert]).to match(/Es sind keine gleichen Gruppen zum Fusionieren vorhanden/)
      is_expected.to redirect_to(group_path(group))
    end

    it "should not offer archived sibling groups" do
      group = groups(:bottom_layer_one)
      groups(:bottom_layer_two).update_attribute(:archived_at, 1.day.ago)

      sign_in(people(:top_leader))

      get :select, params: {id: group.id}

      expect(flash[:alert]).to match(/Es sind keine gleichen Gruppen zum Fusionieren vorhanden/)
      is_expected.to redirect_to(group_path(group))
    end
  end

  # TODO test paths inside perform action
  context "POST :perform" do
    it "should redirect to form if params are missing" do
      group = groups(:bottom_layer_one)

      sign_in(people(:top_leader))

      post :perform, params: {id: group.id, merger: {new_group_name: "foo"}}

      expect(flash[:alert]).to match(/Bitte wähle eine Gruppe mit der fusioniert werden soll/)
      is_expected.to redirect_to(merge_group_path(group))

      post :perform, params: {id: group.id, merger: {merge_group_id: "33"}}

      expect(flash[:alert]).to match(/Name für neue Gruppe muss definiert werden/)
      is_expected.to redirect_to(merge_group_path(group))
    end

    it "shouldn't be possible to merge groups without update rights in both groups" do
      group1 = groups(:bottom_layer_one)
      group2 = groups(:bottom_layer_two)
      group3 = Fabricate(Group::BottomLayer.name.to_s, name: "Foo", parent_id: group1.parent_id)

      user = Fabricate(Group::BottomLayer::Leader.name.to_s, label: "foo", group: group1).person
      Fabricate(Group::BottomLayer::Leader.name.to_s, label: "foo", group: group3, person_id: user.id)

      sign_in(user)

      post :perform, params: {id: group1.id, merger: {new_group_name: "foo", merge_group_id: group2.id}}

      expect(flash[:alert]).to match(/Leider fehlt dir die Berechtigung um diese Gruppen zu fusionieren/)
      is_expected.to redirect_to(merge_group_path(group1))
    end

    it "merges groups" do
      group1 = groups(:bottom_layer_one)
      group2 = groups(:bottom_layer_two)
      parent = groups(:top_layer)

      user = Fabricate(Group::BottomLayer::Leader.name.to_s, group: group1).person
      Fabricate(Group::BottomLayer::Leader.name.to_s, group: group2, person: user)
      Fabricate(Group::TopLayer::TopAdmin.name.to_s, group: parent, person: user)

      sign_in(user)

      post :perform, params: {id: group1.id, merger: {new_group_name: "foo", merge_group_id: group2.id}}

      expect(flash[:alert]).to match(/Die Rechnungseinstellungen werden nicht automatisch übernommen/)
      new_group = Group.order(:id).last
      is_expected.to redirect_to(group_path(new_group))
    end

    it "displays exception from merger in case of unexpected error" do
      group1 = groups(:bottom_layer_one)
      group2 = groups(:bottom_layer_two)
      parent = groups(:top_layer)

      user = Fabricate(Group::BottomLayer::Leader.name.to_s, group: group1).person
      Fabricate(Group::BottomLayer::Leader.name.to_s, group: group2, person: user)
      Fabricate(Group::TopLayer::TopAdmin.name.to_s, group: parent, person: user)

      sign_in(user)

      group2.archive!

      post :perform, params: {id: group1.id, merger: {new_group_name: "foo", merge_group_id: group2.id}}

      expect(flash[:alert]).to match(/Cannot merge archived groups/)
      is_expected.to redirect_to(merge_group_path(group1))
    end

    it "displays validation exception from merger" do
      group1 = groups(:bottom_layer_one)
      group2 = groups(:bottom_layer_two)
      parent = groups(:top_layer)

      invalid_record = Fabricate(:event, groups: [group1])
      invalid_record.errors.add(:base, "invalid from test")
      allow_any_instance_of(Event).to receive(:save!).and_raise(ActiveRecord::RecordInvalid.new(invalid_record))

      user = Fabricate(Group::BottomLayer::Leader.name.to_s, group: group1).person
      Fabricate(Group::BottomLayer::Leader.name.to_s, group: group2, person: user)
      Fabricate(Group::TopLayer::TopAdmin.name.to_s, group: parent, person: user)

      sign_in(user)

      post :perform, params: {id: group1.id, merger: {new_group_name: "foo", merge_group_id: group2.id}}

      expect(flash[:alert]).to match(/invalid from test/)
      is_expected.to redirect_to(merge_group_path(group1))
    end
  end
end
