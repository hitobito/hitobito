#  Copyright (c) 2012-2025, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "spec_helper"

describe Dropdown::LabelItems do
  include Rails.application.routes.url_helpers

  include FormatHelper
  include LayoutHelper
  include UtilityHelper

  let(:user) { people(:top_leader) }
  let(:group_id) { groups(:top_group).id }

  let(:dropdown) do
    Dropdown::PeopleExport.new(
      self,
      user,
      {controller: "people", group_id:}
    )
  end

  subject(:node) { Capybara::Node::Simple.new(dropdown.to_s).find("li", text: "Etiketten") }

  let(:standard) { label_formats(:standard) }

  def export_link(format, address_type = nil)
    params = {label_format_id: label_formats(format).id, format: :pdf, address_type:}.compact_blank
    group_people_path(group_id, params)
  end

  describe "additional_address disabled" do
    before do
      allow(Settings.additional_address).to receive(:enabled).and_return(false)
      described_class.new(dropdown).add
    end

    it "renders all label formats" do
      expect(node).to have_link "Etiketten", href: "#"
      expect(node).to have_css "li a", count: 3
      expect(node).to have_link "Envelope (C6, 1x1)", href: export_link(:envelope)
      expect(node).to have_link "Large (A4, 2x5)", href: export_link(:large)
      expect(node).to have_link "Standard (A4, 3x10)", href: export_link(:standard)
    end
  end

  describe "additional_address enabled" do
    before do
      allow(Settings.additional_address).to receive(:enabled).and_return(true)
      described_class.new(dropdown).add
    end

    it "renders all label formats" do
      expect(node).to have_link "Etiketten", href: "#"
      expect(node).to have_css "li a", count: 15
      expect(node).to have_link "Envelope (C6, 1x1)", href: "#"

      [
        ["Envelope (C6, 1x1)", :envelope],
        ["Large (A4, 2x5)", :large],
        ["Standard (A4, 3x10)", :standard]
      ].each do |text, label_format|
        expect(node).to have_link text, href: "#"
        sublist = node.find("a", text: text).sibling("ul")
        expect(sublist).to have_link "Hauptadresse", href: export_link(label_format, :main)
        expect(sublist).to have_link "Rechnung", href: export_link(label_format, "Rechnung")
        expect(sublist).to have_link "Arbeit", href: export_link(label_format, "Arbeit")
        expect(sublist).to have_link "Andere", href: export_link(label_format, "Andere")
      end
    end
  end
end
