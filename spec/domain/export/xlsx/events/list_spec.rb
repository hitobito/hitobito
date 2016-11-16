require 'spec_helper'

describe Export::Xlsx::Events::List do
  
  let(:courses) { [course1] }
  let(:course1) { events(:top_course) }

  it 'exports events list as xlsx' do
    expect_any_instance_of(Axlsx::Worksheet)
      .to receive(:add_row)
      .exactly(2).times

    Export::Xlsx::Events::List.export(courses)
  end
end
