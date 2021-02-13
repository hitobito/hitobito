#  Copyright (c) 2012-2018, Schweizer Blasmusikverband. This file is part of
#  hitobito_sbv and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "spec_helper"

describe TagListsController do

  before { sign_in(people(:top_leader)) }

  let(:tag_list_double) { instance_double("tag_list") }
  let(:group) { groups(:top_group) }
  let(:leader) { people(:top_leader) }
  let(:bottom_member) { people(:bottom_member) }
  let(:root) { people(:root) }

  context "authorization" do

    before do
      sign_in(people(:bottom_member))
      allow(tag_list_double).to receive(:add).and_return 0
      allow(tag_list_double).to receive(:remove).and_return 0
    end

    it "filters out people whose tags we cannot manage from create request" do
      allow_any_instance_of(TagList).to receive(:new) do |people, _|
        expect(people).to contain_exactly bottom_member
        tag_list_double
      end
      post :create, params: { group_id: group.id, ids: [leader.id, bottom_member.id].join(","), tags: "Tagname" }
    end

    it "filters out people whose tags we cannot manage from destroy request" do
      allow_any_instance_of(TagList).to receive(:new) do |people, _|
        expect(people).to contain_exactly bottom_member
        tag_list_double
      end
      post :destroy, params: { group_id: group.id, ids: [leader.id, bottom_member.id].join(","), tags: "Tagname" }
    end
  end

  context "GET modal for bulk creating tags" do
    it "shows modal" do
      get :new, xhr: true, params: { group_id: group.id, ids: [leader.id, bottom_member.id].join(",") }, format: :js
      expect(response).to have_http_status(:ok)
      expect(response).to render_template("tag_lists/new")
      expect(assigns(:manageable_people)).to contain_exactly leader, bottom_member
    end
  end

  context "POST create" do
    before { allow(controller).to receive(:tag_list).and_return tag_list_double }

    it "creates a tag and displays flash message" do
      expect(tag_list_double).to receive(:add).and_return(1)
      post :create, params: { group_id: group.id, ids: leader.id, tags: "new tag" }
      expect(flash[:notice]).to include "Ein Tag wurde erstellt"
    end

    it "creates zero tags and displays flash message" do
      expect(tag_list_double).to receive(:add).and_return(0)
      post :create, params: { group_id: group.id, ids: leader.id, tags: "new tag" }
      expect(flash[:notice]).to include "Es wurden keine Tags erstellt"
    end

    it "creates many tags and displays flash message" do
      expect(tag_list_double).to receive(:add).and_return(17)
      post :create, params: { group_id: group.id, ids: leader.id, tags: "new tag" }
      expect(flash[:notice]).to include "17 Tags wurden erstellt"
    end
  end

  context "GET modal for bulk deleting tags" do
    it "shows modal" do
      get :deletable, xhr: true, params: { group_id: group.id, ids: [leader.id, bottom_member.id].join(",") }, format: :js
      expect(response).to have_http_status(:ok)
      expect(response).to render_template("tag_lists/deletable")
      expect(assigns(:manageable_people)).to contain_exactly leader, bottom_member
      expect(assigns(:existing_tags)).to be_empty
    end

    it "shows modal with tags and correct count" do
      sign_in(root)
      tag_test  = ActsAsTaggableOn::Tag.find_or_create_with_like_by_name("test")
      tag_once  = ActsAsTaggableOn::Tag.find_or_create_with_like_by_name("once")
      tag_twice = ActsAsTaggableOn::Tag.find_or_create_with_like_by_name("twice")
      leader.tag_list.add(tag_test, tag_once, tag_twice)
      leader.save!
      root.tag_list.add(tag_twice)
      root.save!
      bottom_member.tag_list.add(tag_once, "another")
      bottom_member.save!
      get :deletable, xhr: true, params: { group_id: group.id, ids: [leader.id, root.id].join(",") },
                            format: :js
      expect(response).to have_http_status(:ok)
      expect(response).to render_template("tag_lists/deletable")
      expect(assigns(:manageable_people)).to contain_exactly leader, root
      expect(assigns(:existing_tags)).to contain_exactly([tag_test, 1],
                                                         [tag_once, 1],
                                                         [tag_twice, 2])
    end
  end

  context "DELETE destroy" do
    before { allow(controller).to receive(:tag_list).and_return tag_list_double }

    it "removes a tag and displays flash message" do
      expect(tag_list_double).to receive(:remove).and_return(1)
      post :destroy, params: { group_id: group.id, ids: leader.id, tags: "existing" }
      expect(flash[:notice]).to include "Ein Tag wurde entfernt"
    end

    it "removes zero tags and displays flash message" do
      expect(tag_list_double).to receive(:remove).and_return(0)
      post :destroy, params: { group_id: group.id, ids: leader.id, tags: "existing" }
      expect(flash[:notice]).to include "Es wurden keine Tags entfernt"
    end

    it "removes many tags and displays flash message" do
      expect(tag_list_double).to receive(:remove).and_return(17)
      post :destroy, params: { group_id: group.id, ids: leader.id, tags: "existing" }
      expect(flash[:notice]).to include "17 Tags wurden entfernt"
    end
  end

end
