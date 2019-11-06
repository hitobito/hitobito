require 'spec_helper'

describe HelpTexts::List do
  subject { described_class.new.entries }

  it 'generates entries for a range of controllers' do
    expect(subject).to have_at_least(29).items
  end

  it 'generates entry with fields and actions for custom_contents' do
    entry = subject.find { |e| e.model_class == CustomContent }
    expect(entry.fields).to have_at_least(2).items
    expect(entry.actions).to have_at_least(3).items
  end
end

