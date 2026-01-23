# frozen_string_literal: true

#  Copyright (c) 2026, hitobito AG. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "spec_helper"

describe Dropdown::Invoices do
  include Rails.application.routes.url_helpers

  let(:invoice) { invoices(:invoice) }
  let(:params) { ActionController::Parameters.new({group_id: invoice.group.id, invoice_id: invoice.id}) }
  let(:dropdown) { described_class.new(self, params, type) }

  before do
    allow(self).to receive(:current_user).and_return(people(:top_leader))
    allow(LabelFormat).to receive(:exists?).and_return(false)
    allow(self).to receive(:group_payments_path).and_return("#")
  end

  describe "#export" do
    let(:type) { :download }

    it "adds csv export item" do
      dropdown.export
      csv_item = dropdown.items.find { |item| item.label == "CSV" }
      expect(csv_item).to be_present
      expect(csv_item.url[:format]).to eq(:csv)
    end

    it "adds xlsx export item" do
      dropdown.export
      xlsx_item = dropdown.items.find { |item| item.label == "Excel" }
      expect(xlsx_item).to be_present
      expect(xlsx_item.url[:format]).to eq(:xlsx)
    end
  end
end
