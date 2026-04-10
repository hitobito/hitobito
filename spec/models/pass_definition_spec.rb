# frozen_string_literal: true

#  Copyright (c) 2026, Puzzle ITC. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito

require "spec_helper"

describe PassDefinition do
  subject(:definition) { Fabricate.build(:pass_definition, owner: groups(:top_layer)) }

  it "is valid with default attributes" do
    expect(definition).to be_valid
  end

  context "validations" do
    it "requires a name" do
      definition.name = nil
      expect(definition).not_to be_valid
      expect(definition.errors[:name]).to include(match(/muss ausgefüllt|blank/i))
    end

    it "requires a template_key" do
      definition.template_key = nil
      expect(definition).not_to be_valid
      expect(definition.errors[:template_key]).to be_present
    end

    it "validates template_key is registered" do
      definition.template_key = "nonexistent"
      expect(definition).not_to be_valid
      expect(definition.errors[:template_key]).to be_present
    end

    it "requires a background_color" do
      definition.background_color = nil
      expect(definition).not_to be_valid
      expect(definition.errors[:background_color]).to be_present
    end

    it "validates background_color hex format" do
      definition.background_color = "red"
      expect(definition).not_to be_valid
      expect(definition.errors[:background_color]).to be_present
    end

    it "accepts valid hex colors" do
      definition.background_color = "#ff00aa"
      expect(definition).to be_valid
    end

    it "accepts uppercase hex colors" do
      definition.background_color = "#FF00AA"
      expect(definition).to be_valid
    end

    it "rejects short hex colors" do
      definition.background_color = "#f0a"
      expect(definition).not_to be_valid
    end
  end

  it "#template returns the registered template" do
    template = definition.template
    expect(template).to be_a(Passes::TemplateRegistry::Template)
    expect(template.pass_view_partial).to eq("default")
    expect(template.wallet_data_provider).to eq(Passes::WalletDataProvider)
    expect(template.pdf_class).to be_present
  end
end
