# frozen_string_literal: true

#  Copyright (c) 2026, Puzzle ITC. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "spec_helper"

describe ContactAccountCategoriesController do
  let(:entry) { contact_account_categories(:phone_number_person_work) }

  describe "as root" do
    before { sign_in(people(:root)) }

    context "GET #index" do
      it "lists entries" do
        get :index
        expect(response).to be_successful
      end
    end

    context "GET #new" do
      it "renders form" do
        get :new
        expect(response).to be_successful
      end
    end

    context "GET #edit" do
      it "renders form" do
        get :edit, params: {id: entry.id}
        expect(response).to be_successful
      end
    end

    context "POST #create" do
      it "creates entry" do
        expect do
          post :create, params: {contact_account_category: {
            contact_account_type: "PhoneNumber", contactable_type: "Person",
            key: "new_key", name: "New Category"
          }}
        end.to change { ContactAccountCategory.count }.by(1)
      end
    end

    context "PATCH #update" do
      it "updates entry" do
        expect do
          patch :update, params: {id: entry.id, contact_account_category: {position: 5}}
        end.to change { entry.reload.position }.to(5)
      end
    end

    it "does not route DELETE" do
      expect do
        delete :destroy, params: {id: entry.id}
      end.to raise_error ActionController::UrlGenerationError
    end
  end

  describe "without root permissions" do
    let(:person) { people(:top_leader) }

    before { sign_in(person) }

    context "GET #index" do
      it "does not list entries" do
        expect do
          get :index
        end.to raise_error CanCan::AccessDenied
      end
    end

    context "POST #create" do
      it "does not create entry" do
        expect do
          post :create, params: {contact_account_category: {
            contact_account_type: "PhoneNumber", contactable_type: "Person",
            key: "new_key", name: "New Category"
          }}
        end.to raise_error CanCan::AccessDenied
      end
    end

    context "PATCH #update" do
      it "does not update entry" do
        expect do
          patch :update, params: {id: entry.id, contact_account_category: {position: 5}}
        end.to raise_error CanCan::AccessDenied
      end
    end
  end
end
