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

  it '.list orders by human model name' do
    first = HelpText.create!(context: 'events--event/course', key: 'action.index', body: 'test')
    second = HelpText.create!(context: 'people--person', key: 'action.index', body: 'test')
    third  = HelpText.create!(context: 'mailing_lists--mailing_list', key: 'action.index', body: 'test')

    expect(HelpText.list).to eq [third, first, second]
  end

end
