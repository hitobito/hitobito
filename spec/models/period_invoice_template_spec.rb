#  Copyright (c) 2026, Hitobito AG. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "spec_helper"

describe PeriodInvoiceTemplate do
  let(:group) { groups(:top_layer) }
  let(:period_invoice_template) { Fabricate(:period_invoice_template) }

  it "validates presence of name" do
    period_invoice_template.name = nil

    expect(period_invoice_template).not_to be_valid
    expect(period_invoice_template.errors.full_messages).to include("Bezeichnung muss ausgefüllt werden")
  end

  it "validates presence of start_on" do
    period_invoice_template.start_on = nil

    expect(period_invoice_template).not_to be_valid
    expect(period_invoice_template.errors.full_messages).to include("Rechnungsperiode Start muss ausgefüllt werden")
  end

  it "validates end_on to be after start_on" do
    period_invoice_template.start_on = period_invoice_template.end_on + 1.day

    expect(period_invoice_template).not_to be_valid
    expect(period_invoice_template
           .errors
           .full_messages).to include("Rechnungsperiode Ende kann nicht vor Rechnungsperiode Start sein")
  end

  it "#to_s returns name" do
    expect(period_invoice_template.to_s).to eq(period_invoice_template.name)
  end
end
