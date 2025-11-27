# frozen_string_literal: true

#  Copyright (c) 2012-2025, Swiss Badminton. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "spec_helper"

describe InvoicesHelper do
  include UtilityHelper
  include FormatHelper
  include LayoutHelper

  let(:invoice) { invoices(:invoice) }
  let(:top_leader) { people(:top_leader) }

  describe "#invoice_receiver_address" do
    it "is nil if recipient address is not set" do
      expect(invoice_receiver_address(invoice)).to be_nil
    end

    it "renders person info" do
      invoice.update_columns(recipient_name: "Top Leader", recipient_street: "Greatstreet",
        recipient_housenumber: "345", recipient_zip_code: "3456", recipient_town: "Greattown")

      dom = Capybara::Node::Simple.new(invoice_receiver_address(invoice))

      expect(dom).to have_text "Top Leader"
      expect(dom).to have_text "Greatstreet 345"
      expect(dom).to have_text "3456 Greattown"
      expect(dom).to have_link "top_leader@example.com", href: "mailto:top_leader@example.com"
    end

    it "works with deprecated recipient address" do
      invoice.update_columns(recipient_name: nil, recipient_street: nil, recipient_housenumber: nil,
        recipient_zip_code: nil, recipient_town: nil,
        deprecated_recipient_address: "Top Leader\nGreatstreet 345\n3456 Greattown")

      dom = Capybara::Node::Simple.new(invoice_receiver_address(invoice))
      expect(dom).to have_text "Top Leader"
      expect(dom).to have_text "Greatstreet 345"
      expect(dom).to have_text "3456 Greattown"
      expect(dom).to have_link "top_leader@example.com", href: "mailto:top_leader@example.com"
    end
  end

  describe "format_invoice_recipient" do
    it "returns link to recipient if present" do
      dom = Capybara::Node::Simple.new(format_invoice_recipient(invoice))

      expect(dom).to have_link "Top Leader", href: person_path(top_leader)
    end

    it "returns person name if present" do
      invoice.recipient = nil
      invoice.recipient_name = "Top Leader Name"

      dom = Capybara::Node::Simple.new(format_invoice_recipient(invoice))

      expect(dom).to have_text "Top Leader Name"
    end

    it "returns company name if present" do
      invoice.recipient = nil
      invoice.recipient_name = "Top Leader Name"
      invoice.recipient_company_name = "Top Leader Company"

      dom = Capybara::Node::Simple.new(format_invoice_recipient(invoice))

      expect(dom).to have_text "Top Leader Company"
    end

    it "returns first line of deprecated recipient address" do
      invoice.recipient = nil
      invoice.recipient_name = nil
      invoice.deprecated_recipient_address = "Deprecated Top Leader\nAddress\nTown"

      dom = Capybara::Node::Simple.new(format_invoice_recipient(invoice))

      expect(dom).to have_text "Deprecated Top Leader"
    end
  end
end
