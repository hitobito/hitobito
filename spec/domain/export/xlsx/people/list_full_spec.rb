require 'spec_helper'

describe Export::Xlsx::People::ListFull do

  before do
    PeopleRelation.kind_opposites['parent'] = 'child'
    PeopleRelation.kind_opposites['child'] = 'parent'
  end

  after do
    PeopleRelation.kind_opposites.clear
  end

  let(:person) { people(:top_leader) }
  let(:list) { [person] }

  it 'exports people list full as xlsx' do
    expect_any_instance_of(Axlsx::Worksheet)
      .to receive(:add_row)
      .exactly(2).times.and_call_original

    Export::Xlsx::People::ListFull.export(list)
  end
end
