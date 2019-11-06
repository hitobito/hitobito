require 'spec_helper'

describe HelpTexts::Entry do

  subject { HelpTexts::Entry.new(controller, model_class) }

  context Person do
    let(:controller)  { 'people' }
    let(:model_class) { Person }

    it '#key is computed using class_method' do
      expect(subject.key).to eq HelpTexts::Entry.key(controller, model_class)
    end

    it '#to_s delegates to model_class' do
      expect(subject.to_s).to eq  model_class.to_s
    end

    it '#fields is derived from permitted_attrs' do
      expect(subject.fields).to have(PeopleController.permitted_attrs.size).items
    end

    it '#actions are added from outside' do
      expect(subject.actions).to be_empty
      expect { subject.actions << :foo }.to change { subject.actions }.by([:foo])
    end

    it '#fields_with_labels holds namespaced field name and translation' do
      field, label = subject.fields_with_labels.first
      expect(field).to eq 'field.address'
      expect(label).to eq 'Adresse'
    end

    it '#actions_with_labels holds namespaced action name and translation' do
      subject.actions << 'index'
      field, label = subject.actions_with_labels.first
      expect(field).to eq 'action.index'
      expect(label).to eq 'Liste'
    end

    it '#actions_with_labels only returns whitelisted actions' do
      subject.actions << 'foo'
      expect(subject.actions_with_labels).to be_empty
    end

    it '#grouped returns structure used for grouped_collection_select' do
      subject.actions << 'new'
      expect(subject.grouped).to have(2).items

      actions, fields = subject.grouped
      expect(actions.label).to eq 'Seiten'
      expect(actions.list).to have(1).item
      expect(actions.list.first[0]).to eq 'action.new'
      expect(actions.list.first[1]).to eq 'Erstellen'

      expect(fields.label).to eq 'Felder'
      expect(fields.list).to have_at_least(10).items
      expect(fields.list.first[0]).to eq 'field.address'
      expect(fields.list.first[1]).to eq 'Adresse'
    end

  end
end

