#  Copyright (c) 2026, Hitobito AG. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "spec_helper"

describe PeriodInvoiceTemplate do
  let(:group) { groups(:top_layer) }
  let(:period_invoice_template) { Fabricate(:period_invoice_template) }
  let(:messages) { period_invoice_template.errors.full_messages }

  it "validates presence of name" do
    period_invoice_template.name = nil

    expect(period_invoice_template).not_to be_valid
    expect(messages).to include("Bezeichnung muss ausgefüllt werden")
  end

  it "validates presence of start_on" do
    period_invoice_template.start_on = nil

    expect(period_invoice_template).not_to be_valid
    expect(messages).to include("Rechnungsperiode Start muss ausgefüllt werden")
  end

  it "validates end_on to be after start_on" do
    period_invoice_template.start_on = period_invoice_template.end_on + 1.day

    expect(period_invoice_template).not_to be_valid
    expect(messages).to include("Rechnungsperiode Ende kann nicht vor Rechnungsperiode Start sein")
  end

  it "validates recipient_group_type" do
    period_invoice_template.recipient_group_type = nil
    expect(period_invoice_template).not_to be_valid
    expect(messages).to include("Empfängergruppen muss ausgefüllt werden")
    period_invoice_template.recipient_group_type = "foobar"
    expect(period_invoice_template).not_to be_valid
    expect(messages).to include("Empfängergruppen ist kein gültiger Wert")
    period_invoice_template.recipient_group_type = Group::TopLayer.name
    expect(period_invoice_template).to be_valid
  end

  it "prevents changes to recipient_group_type when invoice runs are present" do
    period_invoice_template.recipient_group_type = Group::TopLayer.name
    expect(period_invoice_template).to be_valid
    period_invoice_template.invoice_runs.build
    expect(period_invoice_template).not_to be_valid
    expect(messages).to include("Empfängergruppen darf nicht mehr verändert werden, da bereits " \
      "Rechnungsläufe existieren")
  end

  it "#to_s returns name" do
    expect(period_invoice_template.to_s).to eq(period_invoice_template.name)
  end
end
