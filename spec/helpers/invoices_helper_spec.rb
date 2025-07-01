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
      invoice.update_columns(recipient_address: Person::Address.new(top_leader).for_invoice)
      dom = Capybara::Node::Simple.new(invoice_receiver_address(invoice))
      expect(dom).to have_link "Top Leader", href: person_path(top_leader)
      expect(dom).to have_text "Greatstreet 345"
      expect(dom).to have_text "3456 Greattown"
      expect(dom).to have_link "top_leader@example.com", href: "mailto:top_leader@example.com"
    end

    it "does not fail if recipient is nil" do
      invoice.update_columns(recipient_address: Person::Address.new(top_leader).for_invoice, recipient_id: nil)
      dom = Capybara::Node::Simple.new(invoice_receiver_address(invoice))
      expect(dom).not_to have_link "Top Leader", href: person_path(top_leader)
      expect(dom).to have_text "Top Leader"
      expect(dom).to have_text "Greatstreet 345"
      expect(dom).to have_text "3456 Greattown"
      expect(dom).to have_link "top_leader@example.com", href: "mailto:top_leader@example.com"
    end
  end
end
