#  Copyright (c) 2026, Hitobito AG. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "spec_helper"

describe Sheet::PeriodInvoiceTemplates::InvoiceRun do
  let(:sheet) { described_class.new(self, nil, invoice_run) }
  let(:invoice_run) { nil }

  it "is nested inside a period invoice template sheet" do
    expect(sheet.parent_sheet).to be_a Sheet::PeriodInvoiceTemplate
    expect(sheet.root).to be_a Sheet::Group
  end

  it "renders the invoices left nav" do
    expect(sheet.left_nav?).to be true
    expect(view).to receive(:render).with("invoices/nav_left", {}).once.and_return("")
    sheet.render_left_nav
  end
end
