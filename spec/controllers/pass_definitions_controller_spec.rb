#  Copyright (c) 2025, Puzzle ITC. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "spec_helper"

describe PassDefinitionsController do
  let(:top_leader) { people(:top_leader) }
  let(:bottom_member) { people(:bottom_member) }
  let(:group) { groups(:top_layer) }

  before do
    Passes::TemplateRegistry.register("default",
      pdf_class: "Object", pass_view_partial: "test", wallet_data_provider: "Object")
  end

  describe "GET #index" do
    it "lists pass definitions for authorized user" do
      sign_in(top_leader)
      Fabricate(:pass_definition, owner: group)
      get :index, params: {group_id: group.id}
      expect(assigns(:pass_definitions)).to have(1).item
    end

    it "lists pass definitions for user with any role" do
      sign_in(bottom_member)
      Fabricate(:pass_definition, owner: group)
      get :index, params: {group_id: group.id}
      expect(assigns(:pass_definitions)).to have(1).item
    end

    it "sorts by name" do
      sign_in(top_leader)
      beta = Fabricate(:pass_definition, owner: group, name: "Beta")
      alpha = Fabricate(:pass_definition, owner: group, name: "Alpha")
      get :index, params: {group_id: group.id}
      expect(assigns(:pass_definitions)).to eq [alpha, beta]
    end
  end

  describe "POST #create" do
    let(:valid_params) do
      {
        group_id: group.id,
        pass_definition: {
          name: "New Pass",
          description: "A test pass",
          template_key: "default",
          background_color: "#ff0000"
        }
      }
    end

    it "creates a new pass definition" do
      sign_in(top_leader)
      expect { post :create, params: valid_params }
        .to change { PassDefinition.count }.by(1)
    end

    it "denies creation for unauthorized user" do
      sign_in(bottom_member)
      expect { post :create, params: valid_params }
        .to raise_error(CanCan::AccessDenied)
    end
  end

  describe "PATCH #update" do
    let!(:pass_definition) { Fabricate(:pass_definition, owner: group) }
    let(:params) do
      {
        group_id: group.id,
        id: pass_definition.id,
        pass_definition: {
          name: "Updated Name",
          description: "Updated description"
        }
      }
    end

    it "updates the pass definition" do
      sign_in(top_leader)
      expect { patch :update, params: params }
        .to change { pass_definition.reload.name }.to("Updated Name")
    end

    it "denies update for unauthorized user" do
      sign_in(bottom_member)
      expect { patch :update, params: params }
        .to raise_error(CanCan::AccessDenied)
    end
  end

  describe "DELETE #destroy" do
    let!(:pass_definition) { Fabricate(:pass_definition, owner: group) }

    it "destroys the pass definition" do
      sign_in(top_leader)
      expect { delete :destroy, params: {group_id: group.id, id: pass_definition.id} }
        .to change { PassDefinition.count }.by(-1)
    end

    it "denies destroy for unauthorized user" do
      sign_in(bottom_member)
      expect { delete :destroy, params: {group_id: group.id, id: pass_definition.id} }
        .to raise_error(CanCan::AccessDenied)
    end
  end
end
