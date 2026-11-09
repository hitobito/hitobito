#  Copyright (c) 2025-2026, Hitobito AG. This file is part of
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

  context "with phone numbers" do
    def phone_number(number, category_key)
      Fabricate(:phone_number, contactable: top_leader, number:,
        category: contact_account_categories(:"phone_number_person_#{category_key}"))
    end

    before do
      phone_number("+41 44 111 11 11", :landline)
      phone_number("+41 79 222 22 22", :mobile)
      phone_number("+41 31 333 33 33", :work)
    end

    def x_position(text)
      text_with_position.find { |_x, _y, t| t == text }&.first
    end

    it "lists the numbers by category in the columns Privat and Mobil" do
      expect(x_position("+41 44 111 11 11")).to eq x_position("Privat")
      expect(x_position("+41 79 222 22 22")).to eq x_position("Mobil")
      expect(subject.strings).not_to include("+41 31 333 33 33")
    end
  end
end
