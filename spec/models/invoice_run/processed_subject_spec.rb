# frozen_string_literal: true

#  Copyright (c) 2026, BdP and DPSG. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "spec_helper"

describe InvoiceRun::ProcessedSubject do
  let(:person) { people(:top_leader) }
  let(:invoice) { invoice_item.invoice }
  let(:invoice_item) { invoice_items(:pens) }
  let(:template_item) { Fabricate(:period_invoice_template).items.first }
  let!(:processed_subject) {
    InvoiceRun::ProcessedSubject.create(
      subject_type: "Person", subject_id: person.id,
      item_id: invoice_item.id, template_item_id: template_item.id
    )
  }

  it "is destroyed automatically when destroying the invoice item" do
    expect { invoice_item.destroy! }.to change(InvoiceRun::ProcessedSubject, :count).by(-1)
    expect { processed_subject.reload }.to raise_error(ActiveRecord::RecordNotFound)
  end
end
