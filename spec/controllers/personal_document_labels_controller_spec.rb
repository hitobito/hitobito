# frozen_string_literal: true

# Copyright (c) 2026. BienenSchweiz. This file is part of
# hitobito and licensed under the Affero General Public License version 3
# or later. See the COPYING file at the top-level directory or at
# https://github.com/hitobito/hitobito

require "spec_helper"

describe PersonalDocumentLabelsController do
  let(:top_leader) { people(:top_leader) }
  let(:label) { Fabricate(:personal_document_label) }

  before { sign_in(top_leader) }

  describe "POST #create" do
    it "redirects to index after create" do
      post :create, params: {personal_document_label: {name: "Medical"}}
      expect(response).to redirect_to(personal_document_labels_path(returning: true))
    end
  end

  describe "PATCH #update" do
    it "redirects to index after update" do
      patch :update, params: {id: label.id, personal_document_label: {name: "Updated"}}
      expect(response).to redirect_to(personal_document_labels_path(returning: true))
    end
  end
end
