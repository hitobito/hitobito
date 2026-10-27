# frozen_string_literal: true

#  Copyright (c) 2026, Puzzle ITC. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito

require "spec_helper"

describe Prawn::Markup::Processor do
  let(:pdf) { Export::Pdf::Document.new.pdf }

  def rendered_strings(html)
    pdf.markup(html)
    PDF::Inspector::Text.analyze(pdf.render).strings
  end

  it "renders blockquote and pre as paragraphs" do
    expect(rendered_strings("<blockquote>Zitat</blockquote><pre>Code</pre><blockquote>Noch eins</blockquote>"))
      .to eq ["Zitat", "Code", "Noch eins"]
  end

  it "keeps line breaks in pre" do
    expect(rendered_strings("<pre>erste\nzweite</pre>".html_safe)).to eq ["erste", "zweite"]
  end
end
