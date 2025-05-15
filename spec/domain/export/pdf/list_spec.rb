#  Copyright (c) 2025, Hitobito AG. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "spec_helper"

describe Export::Pdf::List do
  include PdfHelpers

  let(:top_leader) { people(:top_leader) }
  let(:group) { groups(:top_group) }
  let(:contactables) { [top_leader.tap { |u| u.update(nickname: "Funny Name") }] }
  let(:pdf) { described_class.render(contactables, group) }

  subject { PDF::Inspector::Text.analyze(pdf) }

  it "renders pdf list" do
    pdf_text = [
      [28, 792, "TopGroup"],
      [33, 762, "Name"],
      [149, 762, "Adresse"],
      [293, 762, "E-Mail"],
      [409, 762, "Privat"],
      [442, 762, "Mobil"],
      [33, 747, "Leader Top / Funny Name"],
      [149, 747, "Greatstreet 345, 3456 Greattown"],
      [293, 747, "top_leader@example.com"],
      [513, 19, "Seite 1 von 1"]
    ]

    pdf_text.each_with_index do |text, i|
      expect(text_with_position[i]).to eq(text)
    end
  end
end
