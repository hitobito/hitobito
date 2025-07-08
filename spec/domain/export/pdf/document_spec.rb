# frozen_string_literal: true

#  Copyright (c) 2025, Schweizer Alpen-Club. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito

require "spec_helper"

RSpec.describe Export::Pdf::Document do
  let(:pdf) { subject.pdf }

  it "does not raise error when rendering non-Windows-1252 characters with default font" do
    # the default font is hard coded as "Helvetica" in Prawn::Document#save_font
    pdf.font("Helvetica")
    pdf.text("Hello, world! こんにちは 你好", inline_format: true)

    expect { pdf.render }.not_to raise_error
  end
end
