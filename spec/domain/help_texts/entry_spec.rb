# frozen_string_literal: true

#  Copyright (c) 2019-2024, Pfadibewegung Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_pbs.

require "spec_helper"

describe HelpTexts::Entry do
  subject { HelpTexts::Entry.new(controller, model_class) }

  context Person do
    let(:controller) { "people" }
    let(:model_class) { Person }

    it "#key is computed using class_method" do
      expect(subject.key).to eq HelpTexts::Entry.key(controller, model_class)
    end

    it "#to_s delegates to model_class" do
      expect(subject.to_s).to eq model_class.to_s
    end

    it "#fields is derived from used_attributes" do
      blacklist = Settings.help_text_blacklist.to_h.fetch(:person)
      expect(blacklist).to have_at_least(2).items
      expect(subject.fields).to have_at_least(Person.used_attributes.size - blacklist.size).items
    end

    it "#fields is returned without duplicates" do
      subject = HelpTexts::Entry.new("events", Event::Course)
      expect(subject.fields.uniq.size).to eq(subject.fields.size)
    end

    it "#action_names are added from outside" do
      expect(subject.action_names).to be_empty
      subject.action_names << :foo
      expect(subject.action_names).to eq [:foo]
    end

    it "#fields with label holds namespaced field name and translation" do
      field, label = subject.labeled_list(:field).first
      expect(field).to eq "field.remove_picture"
      expect(label).to eq "Aktuelles Foto entfernen"
    end

    it "#fields with label holds namespaced field name and translation" do
      field, label = subject.labeled_list(:field).first
      expect(field).to eq "field.remove_picture"
      expect(label).to eq "Aktuelles Foto entfernen"
    end

    it "#fields with label filters based on existing fields" do
      field_count = subject.labeled_list(:field).size
      subject = HelpTexts::Entry.new(controller, model_class, {action: [], field: %w[street]})
      expect(subject.labeled_list(:field)).to have(field_count - 1).items
    end

    it "#actions with label holds namespaced action name and translation" do
      subject.action_names << "index"
      field, label = subject.labeled_list(:action).first
      expect(field).to eq "action.index"
      expect(label).to eq "Liste"
    end

    it "#actions with label filters based on existing actions" do
      subject = HelpTexts::Entry.new(controller, model_class, {action: %w[index], field: []})
      subject.action_names << "index"
      expect(subject.labeled_list(:action)).to be_empty
    end

    it "#actions with label only returns whitelisted action_names" do
      subject.action_names << "foo"
      expect(subject.labeled_list(:action)).to be_empty
    end

    context "#grouped" do
      it "returns two arrays if action and fields are present" do
        subject.action_names << "new"
        expect(subject.grouped).to have(2).items
      end

      it "only includes fields if actions are not present" do
        expect(subject.grouped).to have(1).item
      end

      it "returns structure used for grouped_collection_select" do
        subject.action_names << "new"
        expect(subject.grouped).to have(2).items

        action_names, fields = subject.grouped
        expect(action_names.label).to eq "Seiten"
        expect(action_names.list).to have(1).item
        expect(action_names.list.first[0]).to eq "action.new"
        expect(action_names.list.first[1]).to eq "Erstellen"

        expect(fields.label).to eq "Felder"
        expect(fields.list).to have_at_least(10).items
        expect(fields.list.first[0]).to eq "field.remove_picture"
        expect(fields.list.first[1]).to eq "Aktuelles Foto entfernen"
      end
    end

    context "#present?" do
      it "is true if fields are present" do
        expect(subject.actions).to be_empty
        expect(subject.fields).to be_present
        expect(subject).to be_present
      end

      it "is true if actions are present" do
        existing_fields = PeopleController.permitted_attrs.collect(&:to_s)
        subject = HelpTexts::Entry.new(controller, model_class, {action: [], field: existing_fields})
        subject.action_names << "index"
        expect(subject.actions).to be_present
        expect(subject.fields).to be_present
        expect(subject).to be_present
      end

      it "is false if both are empty" do
        existing_fields = PeopleController.permitted_attrs.collect(&:to_s) +
          Person.used_attributes.map(&:to_s)
        subject = HelpTexts::Entry.new(controller, model_class, {action: %w[index], field: existing_fields})
        subject.action_names << "index"
        expect(subject.actions).to be_empty
        expect(subject.fields).to be_empty
        expect(subject).not_to be_present
      end
    end
  end

  context Oauth::Application do
    let(:controller) { "oauth/applications" }
    let(:model_class) { Oauth::Application }

    it "#fields is derived from permitted_attrs" do
      # expect(model_class.try(:used_attributes) || []).to have(0).items
      # expect(subject.send(:used_attributes)).to match_array([])
      # expect(subject.send(:permitted_attributes)).to match_array(
      #   %w(
      #     logo
      #     remove_logo
      #     name
      #     scopes
      #     confidential
      #     redirect_uri
      #   )
      # )

      # expect(subject.send(:existing, :field)).to have(0).items

      blacklist = Settings.help_text_blacklist.to_h.fetch(:"doorkeeper/application")
      expect(blacklist).to have_at_least(3).items

      # expect(blacklist).to match_array(
      #   %w(
      #     confidential
      #     redirect_uri
      #     scopes
      #   )
      # )
      # expect(subject.send(:blacklist_key)).to be :'doorkeeper/application'
      # expect(subject.send(:blacklist)).to match_array(blacklist)

      # expect(subject.fields).to match_array(
      #   subject.send(:permitted_attributes) - blacklist
      # )

      expect(subject.fields).to have(
        Oauth::ApplicationsController.permitted_attrs.size - blacklist.size
      ).items
    end

    context "#present?" do
      it "is true if fields are present" do
        expect(subject.actions).to be_empty
        expect(subject.fields).to be_present
        expect(subject).to be_present
      end

      it "is true if actions are present" do
        existing_fields = Oauth::ApplicationsController.permitted_attrs.collect(&:to_s)
        subject = HelpTexts::Entry.new(controller, model_class, {action: [], field: existing_fields})
        subject.action_names << "index"
        expect(subject.actions).to be_present
        expect(subject.fields).to be_empty
        expect(subject).to be_present
      end

      it "is false if both are empty" do
        existing_fields = Oauth::ApplicationsController.permitted_attrs.collect(&:to_s)
        subject = HelpTexts::Entry.new(controller, model_class, {action: %w[index], field: existing_fields})
        subject.action_names << "index"
        expect(subject.actions).to be_empty
        expect(subject.fields).to be_empty
        expect(subject).not_to be_present
      end
    end
  end
end
