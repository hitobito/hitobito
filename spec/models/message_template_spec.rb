#  frozen_string_literal: true

#  Copyright (c) 2024-2026, Schweizer Wanderwege. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "rails_helper"

describe MessageTemplate, type: :model do
  let(:message_template) { message_templates(:top_layer_one) }

  describe "#valid?" do
    it "validates presence of title" do
      message_template = described_class.new
      expect(message_template).not_to be_valid
      message_template.title = "New Title"
      expect(message_template).to be_valid
    end
  end

  describe "#option_for_select" do
    it "returns usable array" do
      expect(message_template.option_for_select).to match([
        message_template.title, message_template.id,
        data: hash_including(title: message_template.title, body: message_template.body)
      ])
    end

    it "includes texts of all languages" do
      message_template.update!(title_fr: "Modèle", body_fr: "Texte")

      expect(message_template.option_for_select.last[:data]).to include(
        title_de: "Some invoice template", title_fr: "Modèle", title_it: nil,
        body_de: "Some invoice template Text", body_fr: "Texte"
      )
    end
  end
end
