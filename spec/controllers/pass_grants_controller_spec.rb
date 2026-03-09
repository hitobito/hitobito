#  Copyright (c) 2025, Puzzle ITC. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "spec_helper"

describe PassGrantsController do
  before do
    Passes::TemplateRegistry.register("default",
      pdf_class: "Object", pass_view_partial: "test", wallet_data_provider: "Object")
    sign_in(people(:top_leader))
  end

  let(:group) { groups(:top_layer) }
  let(:pass_definition) { Fabricate(:pass_definition, owner: group) }

  context "GET query" do
    it "returns matching groups as json" do
      get :query, params: {
        q: "Bot",
        group_id: group.id,
        pass_definition_id: pass_definition.id
      }

      expect(response).to be_successful
      expect(response.parsed_body).to be_an(Array)
      expect(response.parsed_body.pluck("label").join).to match(/Bottom/)
    end

    it "returns empty array for short query" do
      get :query, params: {
        q: "Bo",
        group_id: group.id,
        pass_definition_id: pass_definition.id
      }

      expect(response.parsed_body).to eq([])
    end

    it "does not include archived groups" do
      groups(:bottom_layer_one).save!
      groups(:bottom_layer_one).archive!
      get :query, params: {
        q: "Bot",
        group_id: group.id,
        pass_definition_id: pass_definition.id
      }

      labels = response.parsed_body.pluck("label").join
      expect(labels).not_to match(/Bottom One/)
    end
  end

  context "GET roles.js" do
    it "loads role types for given group" do
      get :roles, xhr: true, params: {
        group_id: group.id,
        pass_definition_id: pass_definition.id,
        pass_grant: {grantor_id: groups(:bottom_layer_one).id}
      }, format: :js

      expect(assigns(:role_types).root).to eq(Group::BottomLayer)
    end

    it "does not load role types without group" do
      get :roles, xhr: true, params: {
        group_id: group.id,
        pass_definition_id: pass_definition.id
      }, format: :js

      expect(assigns(:role_types)).to be_nil
    end
  end

  context "POST create" do
    it "creates pass_grant with role types" do
      expect do
        expect do
          post :create, params: {
            group_id: group.id,
            pass_definition_id: pass_definition.id,
            pass_grant: {
              grantor_id: groups(:bottom_layer_one).id,
              grantor_type: "Group",
              role_types: [Group::BottomLayer::Leader.sti_name]
            }
          }
        end.to change { PassGrant.count }.by(1)
      end.to change { RelatedRoleType.count }.by(1)

      expect(response).to redirect_to(group_pass_definition_path(group, pass_definition))
    end

    it "without grantor_id replaces validation error" do
      post :create, params: {
        group_id: group.id,
        pass_definition_id: pass_definition.id,
        pass_grant: {grantor_id: "", role_types: []}
      }

      is_expected.to render_template("crud/new")
    end
  end

  context "GET edit" do
    let!(:grant) { Fabricate(:pass_grant, pass_definition: pass_definition, grantor: groups(:bottom_layer_one)) }

    it "renders edit form" do
      get :edit, params: {
        group_id: group.id,
        pass_definition_id: pass_definition.id,
        id: grant.id
      }

      expect(response).to be_successful
      expect(assigns(:selected_group)).to eq(groups(:bottom_layer_one))
      expect(assigns(:role_types)).to be_present
    end
  end

  context "PATCH update" do
    let!(:grant) { Fabricate(:pass_grant, pass_definition: pass_definition, grantor: groups(:bottom_layer_one)) }

    it "updates role types and redirects" do
      patch :update, params: {
        group_id: group.id,
        pass_definition_id: pass_definition.id,
        id: grant.id,
        pass_grant: {
          role_types: [Group::BottomLayer::Leader.sti_name, Group::BottomLayer::Member.sti_name]
        }
      }

      expect(response).to redirect_to(group_pass_definition_path(group, pass_definition))
      expect(grant.reload.related_role_types.map(&:role_type))
        .to contain_exactly(Group::BottomLayer::Leader.sti_name, Group::BottomLayer::Member.sti_name)
    end
  end

  context "DELETE destroy" do
    let!(:grant) { Fabricate(:pass_grant, pass_definition: pass_definition, grantor: groups(:bottom_layer_one)) }

    it "destroys the pass_grant" do
      expect do
        delete :destroy, params: {
          group_id: group.id,
          pass_definition_id: pass_definition.id,
          id: grant.id
        }
      end.to change { PassGrant.count }.by(-1)

      expect(response).to redirect_to(group_pass_definition_path(group, pass_definition))
    end
  end

  context "authorization" do
    it "denies access for unauthorized user" do
      sign_in(people(:bottom_member))
      expect do
        get :new, params: {
          group_id: group.id,
          pass_definition_id: pass_definition.id
        }
      end.to raise_error(CanCan::AccessDenied)
    end
  end
end
