require 'spec_helper'

describe HelpTexts::List do
  subject { described_class.new.entries }

  it 'generates entries for a range of controllers' do
    expect(subject).to have_at_least(29).items
  end

  it 'generates entry with fields and actions for custom_contents' do
    entry = subject.find { |e| e.model_class == CustomContent }
    expect(entry.fields).to have_at_least(2).items
    expect(entry.actions).to have_at_least(2).items
    expect(entry.fields).to include('body')
    expect(entry.actions).to include('edit')
  end

  it 'takes existing help_texts into account' do
    HelpText.create!(controller: 'people', model: 'person', kind: 'action', name: 'edit', body: 'test')
    HelpText.create!(controller: 'custom_contents', model: 'custom_content', kind: 'action', name: 'edit', body: 'test')
    HelpText.create!(controller: 'custom_contents', model: 'custom_content', kind: 'field', name: 'body', body: 'test')
    entry = subject.find { |e| e.model_class == CustomContent }
    expect(entry.fields).not_to include('body')
    expect(entry.actions).not_to include('edit')
  end

end

