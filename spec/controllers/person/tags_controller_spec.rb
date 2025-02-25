#  Copyright (c) 2012-2024, Dachverband Schweizer Jugendparlamente. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "spec_helper"

describe Person::TagsController do
  let(:top_leader) { people(:top_leader) }
  let(:bottom_member) { people(:bottom_member) }

  before { sign_in(top_leader) }

  describe "GET #query" do
    let(:group) { groups(:top_layer) }
    let(:top_leader) { people(:top_leader) }
    let(:bottom_member) { people(:bottom_member) }
    let!(:tag1) { Fabricate(:tag, name: "morelim") }

    before do
      bottom_member.tag_list.add("loremipsum")
      bottom_member.save!
      top_leader.tag_list.add("lorem", "ispum")
      top_leader.save!
    end

    it "returns empty array if no :q param is given" do
      get :query, params: {group_id: group.id, person_id: bottom_member.id}
      expect(JSON.parse(response.body)).to eq([])
    end

    it "returns empty array if no tag matches" do
      get :query, params: {group_id: group.id, person_id: bottom_member.id, q: "lipsum"}
      expect(JSON.parse(response.body)).to eq([])
    end

    it "returns empty array if :q param is not at least 3 chars long" do
      get :query, params: {group_id: group.id, person_id: bottom_member.id, q: "or"}
      expect(JSON.parse(response.body)).to eq([])
    end

    it "returns matching and unassigned tags if :q param at least 3 chars long" do
      get :query, params: {group_id: group.id, person_id: bottom_member.id, q: "ore"}
      expect(JSON.parse(response.body)).to eq([{"label" => "lorem"}, {"label" => "loremipsum"}, {"label" => "morelim"}])
    end

    it "does not return category_validation tags" do
      create_tag(top_leader, PersonTags::Validation::EMAIL_PRIMARY_INVALID)
      create_tag(top_leader, PersonTags::Validation::EMAIL_ADDITIONAL_INVALID)
      get :query, params: {group_id: group.id, person_id: bottom_member.id, q: "invalid"}
      expect(JSON.parse(response.body)).to eq([])
    end
  end

  describe "POST #create" do
    it "creates person tag" do
      post :create, params: {
        group_id: bottom_member.groups.first.id,
        person_id: bottom_member.id,
        acts_as_taggable_on_tag: {name: "lorem"}
      }

      expect(bottom_member.tags.count).to eq(1)
      expect(assigns(:tags).first.first).to eq(:other)
      expect(assigns(:tags).first.second.first.name).to eq("lorem")
      is_expected.to redirect_to group_person_path(bottom_member.groups.first, bottom_member)
    end

    it "ignores creation if name blank" do
      post :create, params: {
        group_id: bottom_member.groups.first.id,
        person_id: bottom_member.id,
        acts_as_taggable_on_tag: {name: ""}
      }

      expect(bottom_member.tags.count).to eq(0)
      is_expected.to redirect_to group_person_path(bottom_member.groups.first, bottom_member)
    end

    it "trims whitespace characters at end of word to find matching tag" do
      ActsAsTaggableOn::Tag.create!(name: "lorem")

      post :create, params: {
        group_id: bottom_member.groups.first.id,
        person_id: bottom_member.id,
        acts_as_taggable_on_tag: {name: "lorem "}
      }

      expect(bottom_member.tags.count).to eq(1)
      expect(assigns(:tags).first.second.first.name).to eq("lorem")
    end

    it "tag with space in between is not the same as tag without spaces" do
      ActsAsTaggableOn::Tagging.create!(
        taggable: bottom_member,
        tag: ActsAsTaggableOn::Tag.create!(name: "lorem"),
        context: "tags"
      )

      post :create, params: {
        group_id: bottom_member.groups.first.id,
        person_id: bottom_member.id,
        acts_as_taggable_on_tag: {name: "lor em"}
      }

      expect(bottom_member.tags.count).to eq(2)
      expect(assigns(:tags).last.second.first.name).to eq("lor em")
    end
  end

  describe "DELETE #destroy" do
    it "deletes person taggging/assignment" do
      bottom_member.tag_list.add("lorem")
      bottom_member.save!

      expect do
        delete :destroy, params: {
          group_id: bottom_member.groups.first.id,
          person_id: bottom_member.id,
          name: "lorem"
        }
      end.to change(ActsAsTaggableOn::Tagging, :count).by(-1)

      expect(bottom_member.tags.count).to eq(0)
      is_expected.to redirect_to group_person_path(bottom_member.groups.first, bottom_member)
    end

    it "does not delete the tag itself" do
      bottom_member.tag_list.add("lorem")
      bottom_member.save!

      expect do
        delete :destroy, params: {
          group_id: bottom_member.groups.first.id,
          person_id: bottom_member.id,
          name: "lorem"
        }
      end.to change(ActsAsTaggableOn::Tag, :count).by(0)

      expect(bottom_member.tags.count).to eq(0)
      is_expected.to redirect_to group_person_path(bottom_member.groups.first, bottom_member)
    end
  end

  private

  def create_tag(person, name)
    ActsAsTaggableOn::Tagging.create!(
      taggable: person,
      tag: ActsAsTaggableOn::Tag.find_or_create_by(name: name),
      context: "tags"
    )
  end
end
