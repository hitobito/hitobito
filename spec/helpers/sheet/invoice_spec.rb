# frozen_string_literal: true

#  Copyright (c) 2012-2024, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "spec_helper"

describe Sheet::Invoice do
  let(:invoice) { Fabricate.build(:invoice) }
  let(:group) { groups(:bottom_group_one_one) }
  let(:sheet) { Sheet::Invoice.new(self, nil, invoice) }
  let(:mailing_list) { mailing_lists(:leaders) }

  let(:invoice_list) { InvoiceList.create(title: "Mitgliedsbeiträge", group_id: group.id, receiver: mailing_list) }

  it "uses Rechnungen als fallback title" do
    expect(sheet.title).to eq "Rechnungen"
  end

  it "includes receiver in title" do
    view.params[:invoice_list_id] = invoice_list.id
    expect(sheet.title).to eq "Mitgliedsbeiträge - Leaders (Abo)"
  end

  it "does not fail if receiver is missing" do
    view.params[:invoice_list_id] = invoice_list.id
    invoice_list.update!(receiver_id: nil, receiver_type: nil)
    expect(sheet.title).to eq "Mitgliedsbeiträge"
  end
end
