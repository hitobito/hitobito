require "spec_helper"

describe HelpText do

  it "assigns from context and key for new records" do
    ht = help_texts(:events_action_index)
    expect(ht.controller).to eq "events"
    expect(ht.model).to eq "event/course"
    expect(ht.kind).to eq "action"
    expect(ht.name).to eq "index"
  end

  it "#to_s includes all information for persisted record" do
    ht = HelpText.new
    expect(ht.to_s).to be_nil

    ht = help_texts(:people_action_index)
    expect(ht.to_s).to eq 'Person - Seite "Liste"'

    ht = help_texts(:person_field_name)
    expect(ht.to_s).to eq 'Person - Feld "Name"'
  end

  it ".list orders by human model name" do
    first = help_texts(:course_field_name)
    second = help_texts(:people_action_index)
    third  = help_texts(:events_action_index)
    HelpText.where.not(id: [first.id, second.id, third.id]).destroy_all

    expect(HelpText.list).to eq [third, first, second]
  end

end
