require 'spec_helper'

describe HelpText do

  it 'assigns from context and key for new records' do
    ht = HelpText.create!(context: 'events--event/course', key: 'action.index', body: 'test')
    expect(ht.controller).to eq 'events'
    expect(ht.model).to eq 'event/course'
    expect(ht.kind).to eq 'action'
    expect(ht.name).to eq 'index'
  end

  it '#to_s includes all information for persisted record' do
    ht = HelpText.new
    expect(ht.to_s).to be_nil

    ht = HelpText.create!(context: 'events--event/course', key: 'action.index', body: 'test')
    expect(ht.to_s).to eq 'Kurs - Seite "Liste"'

    ht = HelpText.create!(context: 'events--event/course', key: 'field.name', body: 'test')
    expect(ht.to_s).to eq 'Kurs - Feld "Name"'
  end

end
