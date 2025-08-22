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
  let(:pdf) { described_class.render(contactables, group.name) }

  subject { PDF::Inspector::Text.analyze(pdf) }

  it "renders pdf list" do
    pdf_text = [
      [28, 792, "TopGroup"],
      [28, 762, "Name"],
      [143, 762, "Adresse"],
      [286, 762, "E-Mail"],
      [401, 762, "Privat"],
      [433, 762, "Mobil"],
      [28, 747, "Leader Top / Funny Name"],
      [143, 747, "Greatstreet 345, 3456 Greattown"],
      [286, 747, "top_leader@example.com"],
      [513, 19, "Seite 1 von 1"]
    ]

    pdf_text.each_with_index do |text, i|
      expect(text_with_position[i]).to eq(text)
    end
  end
end
