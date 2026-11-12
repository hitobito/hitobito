# frozen_string_literal: true

#  Copyright (c) 2026, Schweizer Wanderwege. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "spec_helper"

describe Export::Pdf::LineTruncator do
  let(:pdf) { Export::Pdf::Document.new.pdf }
  let(:width) { pdf.width_of("Bahnhofstrasse 4") }

  subject(:truncator) { described_class.new(pdf, width) }

  it "keeps lines fitting the width" do
    expect(truncator.truncate("Hans Muster\nBahnhofstrasse 4")).to eq "Hans Muster\nBahnhofstrasse 4"
  end

  it "cuts lines exceeding the width" do
    line = "c/o Treuhand Meier, Chalet Edelweiss"
    first, second = truncator.truncate("#{line}\n3011 Bern").split("\n")

    expect(line).to start_with(first)
    expect(pdf.width_of(first)).to be <= width
    expect(pdf.width_of(line[0, first.size + 1])).to be > width
    expect(second).to eq "3011 Bern"
  end

  it "keeps empty lines" do
    expect(truncator.truncate("Hans Muster\n3011 Bern\n")).to eq "Hans Muster\n3011 Bern\n"
  end

  it "measures with given font options" do
    truncator = described_class.new(pdf, width, size: pdf.font_size * 2)
    expect(pdf.width_of(truncator.truncate("Bahnhofstrasse 4"), size: pdf.font_size * 2))
      .to be <= width
  end
end
