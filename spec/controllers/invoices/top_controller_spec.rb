# frozen_string_literal: true

#  Copyright (c) 2022, Schweizer Wanderwege. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "spec_helper"

describe Invoices::TopController do
  let(:person) { people(:bottom_member) }
  let(:invoice) { invoices(:invoice) }

  before { sign_in(person) }

  context "GET show" do
    context "html" do
      it "redirects to group invoice path" do
        get :show, params: {id: invoice.id}
        is_expected.to redirect_to(group_invoice_path(invoice.group, invoice, format: :html))
      end
    end

    context "json with token" do
      it "forwards token param in redirect" do
        get :show, params: {id: invoice.id, token: "secret", format: :json}
        is_expected.to redirect_to(group_invoice_path(invoice.group, invoice, format: :json, token: "secret"))
      end
    end
  end
end
