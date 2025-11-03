# frozen_string_literal: true

#  Copyright (c) 2025, Schweizer Alpen-Club. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito

require "spec_helper"

describe Export::Xlsx::Generator do
  let(:exportable) do
    labels = ["Header 1", "Header 2"]
    double(
      labels:,
      header_rows: [[labels]],
      data_rows: [["hello", "world"]],
      auto_filter: false,
      sheet_name: nil
    )
  end

  describe "sheet_name" do
    def generate_xlsx
      expect_any_instance_of(Axlsx::Workbook)
        .to receive(:add_worksheet)
        .and_wrap_original do |m, *args|
        m.call(*args).tap do |worksheet|
          yield worksheet
        end
      end

      described_class.new(exportable).call
    end

    it "uses default sheet_name when none provided" do
      generate_xlsx do |worksheet|
        expect(worksheet.name).to eq "Sheet1"
      end
    end

    it "trims sheet name to 31 characters" do
      long_name = "A" * 50
      allow(exportable).to receive(:sheet_name).and_return(long_name)

      generate_xlsx do |worksheet|
        expect(worksheet.name).to eq "A" * 31
      end
    end
  end
end
