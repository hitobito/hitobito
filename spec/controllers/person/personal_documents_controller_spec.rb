# Copyright (c) 2026. BienenSchweiz. This file is part of
# hitobito and licensed under the Affero General Public License version 3
# or later. See the COPYING file at the top-level directory or at
# https://github.com/hitobito/hitobito

require "spec_helper"

describe Person::PersonalDocumentsController do
  let(:top_leader) { people(:top_leader) }
  let(:bottom_member) { people(:bottom_member) }
  let(:group) { bottom_member.groups.first }

  before { sign_in(top_leader) }

  describe "GET #index" do
    let!(:personal_document) { Fabricate(:personal_document, person: bottom_member) }

    it "renders successfully" do
      get :index, params: {group_id: group.id, person_id: personal_document.person_id}
      expect(response).to be_successful
      expect(assigns(:personal_documents).to_a).to eq [personal_document]
    end

    context "when other documents exist" do
      before do
        Fabricate.times(5, :personal_document)
      end

      it "renders only the ones of the person" do
        get :index, params: {group_id: group.id, person_id: personal_document.person_id}
        expect(response).to be_successful
        expect(assigns(:personal_documents)).to eq [personal_document]
      end
    end
  end

  describe "POST #create" do
    let(:personal_document_label) { Fabricate(:personal_document_label) }
    let(:create_params) do
      {
        group_id: group.id,
        person_id: bottom_member.id,
        personal_document: {
          person_id: bottom_member.id,
          file: Rack::Test::UploadedFile.new(Rails.root.join("spec", "fixtures", "files", "images", "logo.png")),
          label_id: personal_document_label.id
        }
      }
    end

    it "creates new personal_document" do
      expect do
        post :create, params: create_params
      end.to change(PersonalDocument, :count).by(1)

      expect(response).to redirect_to(
        group_person_personal_documents_path(group, bottom_member, returning: true)
      )
    end
  end

  context "without admin permission" do
    before { sign_in(bottom_member) }

    describe "GET #index" do
      it "raises CanCan::AccessDenied when accessing another person's documents" do
        expect do
          get :index, params: {group_id: groups(:top_group).id, person_id: top_leader.id}
        end.to raise_error(CanCan::AccessDenied)
      end
    end

    describe "GET #show" do
      let!(:other_document) { Fabricate(:personal_document, person: top_leader) }

      it "raises CanCan::AccessDenied when accessing another person's document" do
        expect do
          get :show, params: {group_id: group.id, person_id: top_leader.id, id: other_document.id}
        end.to raise_error(CanCan::AccessDenied)
      end
    end

    describe "GET #new" do
      it "raises CanCan::AccessDenied" do
        expect do
          get :new, params: {group_id: group.id, person_id: bottom_member.id}
        end.to raise_error(CanCan::AccessDenied)
      end
    end

    describe "POST #create" do
      it "raises CanCan::AccessDenied" do
        expect do
          post :create, params: {group_id: group.id, person_id: bottom_member.id, personal_document: {}}
        end.to raise_error(CanCan::AccessDenied)
      end
    end

    describe "GET #edit" do
      let!(:document) { Fabricate(:personal_document, person: bottom_member) }

      it "raises CanCan::AccessDenied" do
        expect do
          get :edit, params: {group_id: group.id, person_id: bottom_member.id, id: document.id}
        end.to raise_error(CanCan::AccessDenied)
      end
    end

    describe "PATCH #update" do
      let!(:document) { Fabricate(:personal_document, person: bottom_member) }

      it "raises CanCan::AccessDenied" do
        expect do
          patch :update,
            params: {group_id: group.id, person_id: bottom_member.id, id: document.id, personal_document: {}}
        end.to raise_error(CanCan::AccessDenied)
      end
    end

    describe "DELETE #destroy" do
      let!(:document) { Fabricate(:personal_document, person: bottom_member) }

      it "raises CanCan::AccessDenied" do
        expect do
          delete :destroy, params: {group_id: group.id, person_id: bottom_member.id, id: document.id}
        end.to raise_error(CanCan::AccessDenied)
      end
    end
  end
end
