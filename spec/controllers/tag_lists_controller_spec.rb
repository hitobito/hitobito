#  Copyright (c) 2012-2018, Schweizer Blasmusikverband. This file is part of
#  hitobito_sbv and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "spec_helper"

describe TagListsController do
  before { sign_in(people(:top_leader)) }

  let(:group) { groups(:top_group) }
  let(:leader) { people(:top_leader) }
  let(:bottom_member) { people(:bottom_member) }
  let(:root) { people(:root) }

  let(:tag_list_double) { double("tag_list") }

  context "authorization" do
    it "filters out people whose tags we cannot manage from create request" do
      post :create, params: {
        group_id: group.id,
        ids: [root.id, bottom_member.id].join(","),
        tags: "Tagname"
      }

      expect(assigns(:manageable_people)).to contain_exactly bottom_member
    end

    it "leaves people whose tags we can manage from create request" do
      post :create, params: {
        group_id: group.id,
        ids: [leader.id, bottom_member.id].join(","),
        tags: "Tagname"
      }

      expect(assigns(:manageable_people)).to contain_exactly leader, bottom_member
    end

    it "filters out people whose tags we cannot manage from destroy request" do
      post :destroy, params: {
        group_id: group.id,
        ids: [root.id, bottom_member.id].join(","),
        tags: "Tagname"
      }

      expect(assigns(:manageable_people)).to contain_exactly bottom_member
    end
  end

  context "GET modal for bulk creating tags" do
    it "shows modal for select people" do
      person_query_double = double("person_query")
      allow(Person).to receive(:from).and_return(person_query_double)
      allow(person_query_double).to receive(:count).and_return(2)

      get :new, xhr: true, params: {
        group_id: group.id,
        ids: [leader.id, bottom_member.id].join(",")
      }, format: :js

      expect(response).to have_http_status(:ok)
      expect(response).to render_template("tag_lists/new")

      expect(assigns(:manageable_people))
        .to contain_exactly(leader, bottom_member)
        .and have(person_query_double.count).items
    end

    it "shows modal for all people" do
      role_type_ids = [leader, bottom_member].map do |p|
        p.roles.map { |r| r.class.id }
      end.flatten.uniq

      get :new, xhr: true,
        params: {
          group_id: group.id,
          ids: "all",
          filters: {role: {kind: "active_today", role_type_ids: role_type_ids}},
          range: "deep"
        }, format: :js

      expect(response).to have_http_status(:ok)
      expect(response).to render_template("tag_lists/new")
      expect(assigns(:manageable_people)).to contain_exactly leader, bottom_member
    end
  end

  context "POST create" do
    it "creates a tag and displays flash message" do
      expect do
        post :create, params: {group_id: group.id, ids: [bottom_member.id], tags: "new tag"}
        expect(flash[:notice]).to include "Ein Tag wurde erstellt"
      end.to change(Delayed::Job, :count).by(1)
    end

    it "creates zero tags and displays flash message" do
      expect(tag_list_double).to receive(:add).and_return(0)
      post :create, params: {group_id: group.id, ids: [], tags: "new tag"}
      expect(flash[:notice]).to include "Es wurden keine Tags erstellt"
    end

    it "creates many tags and displays flash message" do
      expect(tag_list_double).to receive(:add).and_return(17)
      post :create, params: {group_id: group.id, ids: leader.id, tags: "new tag"}
      expect(flash[:notice]).to include "17 Tags wurden erstellt"
    end

    it "creates many tags on 'all' and displays flash message" do
      flunk
    end
  end

  context "GET modal for bulk deleting tags" do
    it "shows modal" do
      get :deletable, xhr: true, params: {
                                   group_id: group.id,
                                   ids: [leader.id, bottom_member.id].join(",")
                                 },
        format: :js
      expect(response).to have_http_status(:ok)
      expect(response).to render_template("tag_lists/deletable")
      expect(assigns(:manageable_people)).to contain_exactly leader, bottom_member
      expect(assigns(:existing_tags)).to be_empty
    end

    it "shows modal with tags and correct count" do
      sign_in(root)
      tag_test = ActsAsTaggableOn::Tag.find_or_create_with_like_by_name("test")
      tag_once = ActsAsTaggableOn::Tag.find_or_create_with_like_by_name("once")
      tag_twice = ActsAsTaggableOn::Tag.find_or_create_with_like_by_name("twice")
      leader.tag_list.add(tag_test, tag_once, tag_twice)
      leader.save!
      root.tag_list.add(tag_twice)
      root.save!
      bottom_member.tag_list.add(tag_once, "another")
      bottom_member.save!
      get :deletable, xhr: true, params: {group_id: group.id, ids: [leader.id, root.id].join(",")},
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
      post :destroy, params: {group_id: group.id, ids: leader.id, tags: "existing"}
      expect(flash[:notice]).to include "Ein Tag wurde entfernt"
    end

    it "removes zero tags and displays flash message" do
      expect(tag_list_double).to receive(:remove).and_return(0)
      post :destroy, params: {group_id: group.id, ids: leader.id, tags: "existing"}
      expect(flash[:notice]).to include "Es wurden keine Tags entfernt"
    end

    it "removes many tags and displays flash message" do
      expect(tag_list_double).to receive(:remove).and_return(17)
      post :destroy, params: {group_id: group.id, ids: leader.id, tags: "existing"}
      expect(flash[:notice]).to include "17 Tags wurden entfernt"
    end
  end
end
