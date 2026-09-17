#  Copyright (c) 2017, Pfadibewegung Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "spec_helper"

describe Export::Tabular::Events::List do
  let(:scope) { Event::Course.where(id: course1.id) }
  let(:course1) { events(:top_course) }

  it "exports events list as xlsx" do
    expect_any_instance_of(Axlsx::Worksheet)
      .to receive(:add_row)
      .twice.and_call_original

    Export::Tabular::Events::List.xlsx(scope)
  end

  it "styles application dates as date columns" do
    course1.update!(
      application_opening_at: Date.new(2024, 1, 15),
      application_closing_at: Date.new(2024, 2, 20)
    )

    list = Export::Tabular::Events::List.new(scope)
    opening_index = list.attributes.index(:application_opening_at)
    closing_index = list.attributes.index(:application_closing_at)

    worksheet = nil
    allow_any_instance_of(Axlsx::Workbook).to receive(:add_worksheet).and_wrap_original do |m, *args, &block|
      m.call(*args) do |sheet|
        block.call(sheet)
        worksheet = sheet
      end
    end

    Export::Tabular::Events::List.xlsx(scope)

    data_row = worksheet.rows.last
    date_num_fmt_id = 14

    [opening_index, closing_index].each do |index|
      style_id = data_row.cells[index].style
      expect(worksheet.workbook.styles.cellXfs[style_id].numFmtId).to eq(date_num_fmt_id)
    end

    expect(data_row.cells[opening_index].value).to eq(Date.new(2024, 1, 15))
    expect(data_row.cells[closing_index].value).to eq(Date.new(2024, 2, 20))
  end
end
