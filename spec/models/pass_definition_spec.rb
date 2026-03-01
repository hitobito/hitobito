#  Copyright (c) 2025, Puzzle ITC. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

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

    it "accepts the default template_key" do
      definition.template_key = "default"
      expect(definition).to be_valid
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

    it "rejects short hex colors" do
      definition.background_color = "#f0a"
      expect(definition).not_to be_valid
    end
  end

  context "associations" do
    it "belongs to owner (Group)" do
      expect(definition.owner).to eq(groups(:top_layer))
    end

    it "has many pass_grants" do
      definition.save!
      grant = Fabricate(:pass_grant, pass_definition: definition,
        grantor: groups(:top_group))
      expect(definition.pass_grants).to include(grant)
    end

    it "has many pass_memberships" do
      definition.save!
      membership = Fabricate(:pass_membership, pass_definition: definition)
      expect(definition.pass_memberships).to include(membership)
    end

    it "has many pass_installations through pass_memberships" do
      definition.save!
      membership = Fabricate(:pass_membership, pass_definition: definition)
      installation = Fabricate(:wallets_pass_installation, pass_membership: membership)
      expect(definition.pass_installations).to include(installation)
    end

    it "destroys dependent pass_grants" do
      definition.save!
      Fabricate(:pass_grant, pass_definition: definition, grantor: groups(:top_group))
      expect { definition.destroy }.to change { PassGrant.count }.by(-1)
    end

    it "destroys dependent pass_memberships" do
      definition.save!
      Fabricate(:pass_membership, pass_definition: definition)
      expect { definition.destroy }.to change { PassMembership.count }.by(-1)
    end
  end

  context "Globalized" do
    it "translates name" do
      expect(PassDefinition.translated_attribute_names).to include(:name)
    end

    it "translates description" do
      expect(PassDefinition.translated_attribute_names).to include(:description)
    end

    it "persists translations" do
      definition.save!
      I18n.with_locale(:de) { definition.update!(name: "Mitgliederausweis") }
      I18n.with_locale(:fr) { definition.update!(name: "Carte de membre") }

      I18n.with_locale(:de) { expect(definition.name).to eq("Mitgliederausweis") }
      I18n.with_locale(:fr) { expect(definition.name).to eq("Carte de membre") }
    end
  end

  context "#template" do
    it "returns the registered template" do
      template = definition.template
      expect(template).to be_a(Passes::TemplateRegistry::Template)
      expect(template.key).to eq("default")
    end

    it "raises for unknown template_key" do
      definition.template_key = "nonexistent"
      expect { definition.template }.to raise_error(KeyError)
    end
  end
end
