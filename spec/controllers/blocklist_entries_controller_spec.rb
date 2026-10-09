# frozen_string_literal: true

#  Copyright (c) 2026, BdP and DPSG. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "spec_helper"

describe BlocklistEntriesController do
  let(:entry) { BlocklistEntry.create!(manual_person_attributes: {first_name: "Max", last_name: "Mustermann"}) }

  before { sign_in(user) }

  context "as admin" do
    let(:user) { people(:top_leader) }

    it "GET #index lists entries" do
      entry
      get :index

      expect(response).to be_successful
      expect(assigns(:blocklist_entries)).to eq [entry]
    end

    it "POST #create creates entry from manual attributes" do
      expect do
        post :create, params: {blocklist_entry: {manual_person_attributes: {first_name: "Max",
                                                                            last_name: "Mustermann",
                                                                            birthday: "15.01.1980"}}}
      end.to change { BlocklistEntry.count }.by(1)

      created = BlocklistEntry.last
      expect(created.blocked_hash).to eq Digest::MD5.hexdigest(".max.mustermann.1980-01-15 00:00:00")
      expect(created.creator).to eq user
      expect(response).to redirect_to(blocklist_entries_path(returning: true))
    end

    it "POST #create creates entry from person and links to it" do
      person = people(:bottom_member)

      expect do
        post :create, params: {blocklist_entry: {person_id: person.id}}
      end.to change { BlocklistEntry.count }.by(1)

      expect(Person::BlocklistDetector.new(person.reload)).to be_blocklisted
      expect(person).to be_valid
      expect(flash[:notice]).to include(person_path(person))
    end

    it "POST #create rerenders form for invalid entry" do
      expect do
        post :create, params: {blocklist_entry: {manual_person_attributes: {first_name: ""}}}
      end.not_to change { BlocklistEntry.count }

      expect(response).to render_template("new")
    end

    context "with views" do
      render_views

      it "GET #index renders entries" do
        entry.update_columns(creator_id: user.id)
        get :index

        expect(response.body).to include(entry.blocked_hash)
        expect(response.body).to include(user.to_s)
      end

      it "GET #new renders form" do
        get :new

        expect(response.body).to include("blocklist_entry[person_id]")
        expect(response.body).to include("blocklist_entry[manual_person_attributes][birthday]")
        expect(page_buttons_count).to eq 2
      end

      it "POST #create rerenders form with errors" do
        post :create, params: {blocklist_entry: {manual_person_attributes: {first_name: ""}}}

        expect(response.body).to include("Bitte eine Person suchen oder Angaben erfassen.")
      end
    end

    def page_buttons_count
      Capybara.string(response.body).all("button[type=submit]", text: "Speichern").count
    end

    it "DELETE #destroy removes entry" do
      entry

      expect do
        delete :destroy, params: {id: entry.id}
      end.to change { BlocklistEntry.count }.by(-1)
    end
  end

  context "as non admin" do
    let(:user) { people(:bottom_member) }

    it "GET #index is denied" do
      expect { get :index }.to raise_error(CanCan::AccessDenied)
    end

    it "POST #create is denied" do
      expect do
        post :create, params: {blocklist_entry: {manual_person_attributes: {last_name: "Mustermann"}}}
      end.to raise_error(CanCan::AccessDenied)
    end

    it "DELETE #destroy is denied" do
      expect { delete :destroy, params: {id: entry.id} }.to raise_error(CanCan::AccessDenied)
    end
  end
end
