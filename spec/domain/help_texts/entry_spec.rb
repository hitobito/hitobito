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

    it '#fields is returned without duplicates' do
      subject = HelpTexts::Entry.new('events', Event::Course)
      expect(subject.fields.uniq.size).to eq (subject.fields.size)
    end

    it '#action_names are added from outside' do
      expect(subject.action_names).to be_empty
      expect { subject.action_names << :foo }.to change { subject.action_names }.by([:foo])
    end

    it '#fields with label holds namespaced field name and translation' do
      field, label = subject.labeled_list(:field).first
      expect(field).to eq 'field.address'
      expect(label).to eq 'Adresse'
    end

    it '#fields with label holds namespaced field name and translation' do
      field, label = subject.labeled_list(:field).first
      expect(field).to eq 'field.address'
      expect(label).to eq 'Adresse'
    end

    it '#fields with label filters based on existing fields' do
      field_count = subject.labeled_list(:field).size
      subject = HelpTexts::Entry.new(controller, model_class, { action: [], field: %w(address) })
      expect(subject.labeled_list(:field)).to have(field_count - 1).items
    end

    it '#actions with label holds namespaced action name and translation' do
      subject.action_names << 'index'
      field, label = subject.labeled_list(:action).first
      expect(field).to eq 'action.index'
      expect(label).to eq 'Liste'
    end

    it '#actions with label filters based on existing actions' do
      subject = HelpTexts::Entry.new(controller, model_class, { action: %w(index), field: [] })
      subject.action_names << 'index'
      expect(subject.labeled_list(:action)).to be_empty
    end

    it '#actions with label only returns whitelisted action_names' do
      subject.action_names << 'foo'
      expect(subject.labeled_list(:action)).to be_empty
    end

    it '#grouped returns structure used for grouped_collection_select' do
      subject.action_names << 'new'
      expect(subject.grouped).to have(2).items

      action_names, fields = subject.grouped
      expect(action_names.label).to eq 'Seiten'
      expect(action_names.list).to have(1).item
      expect(action_names.list.first[0]).to eq 'action.new'
      expect(action_names.list.first[1]).to eq 'Erstellen'

      expect(fields.label).to eq 'Felder'
      expect(fields.list).to have_at_least(10).items
      expect(fields.list.first[0]).to eq 'field.address'
      expect(fields.list.first[1]).to eq 'Adresse'
    end

  end
end

