#  Copyright (c) 2026, Hitobito AG. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "spec_helper"

describe Sheet::PeriodInvoiceTemplate do
  let(:sheet) { Sheet::PeriodInvoiceTemplate.new(self, nil, period_invoice_template) }

  context "index" do
    let(:period_invoice_template) { nil }

    it "uses Sammelrechnungen as title on list" do
      expect(sheet.title).to eq "Sammelrechnungen"
    end

    it "does not have any tabs" do
      expect(sheet.tabs.collect { |tab| tab.renderer(sheet.view, sheet.path_args) }.count(&:show?)).to be_zero
    end
  end

  context "new" do
    let(:period_invoice_template) { PeriodInvoiceTemplate.new(group: Group.root) }

    it "uses name of period invoice template as title on show" do
      expect(sheet.title).to eq "Sammelrechnungen"
    end
  end

  context "show" do
    let(:period_invoice_template) { Fabricate(:period_invoice_template) }

    it "uses name of period invoice template as title on show" do
      expect(sheet.title).to eq period_invoice_template.name
    end

    it "does have two tabs" do
      expect(sheet.tabs.collect { |tab| tab.renderer(sheet.view, sheet.path_args) }.count(&:show?)).to eq 2
    end
  end
end
