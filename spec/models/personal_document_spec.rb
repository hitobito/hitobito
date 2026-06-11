# Copyright (c) 2026. BienenSchweiz. This file is part of
# hitobito and licensed under the Affero General Public License version 3
# or later. See the COPYING file at the top-level directory or at
# https://github.com/hitobito/hitobito

require "rails_helper"

RSpec.describe PersonalDocument, type: :model do
  let(:personal_document_label) { Fabricate(:personal_document_label, name: "Test Label") }

  subject(:personal_document) { Fabricate(:personal_document, personal_document_label:) }

  context "#to_s" do
    it "renders the label" do
      expect(personal_document.to_s).to eq("Test Label")
    end
  end
end
