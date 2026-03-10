# frozen_string_literal: true

#  Copyright (c) 2022, Schweizer Wanderwege. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "spec_helper"

describe FullTextController, type: :controller do
  render_views

  let(:dom) { Capybara::Node::Simple.new(response.body) }

  describe "GET #index" do
    let(:group) { groups(:top_layer) }
    let(:user) { Fabricate(Group::TopLayer::TopAdmin.name.to_sym, group: group).person }

    before do
      allow_any_instance_of(FullTextController).to receive(:only_result).and_return(nil)
      sign_in(user)
    end

    context "with finance permissions" do
      let(:user) { people(:top_leader) }

      it "renders invoices tab" do
        get :index, params: {q: "bla"}

        expect(dom.all(:css, ".nav.nav-tabs")[0].text).to include "Rechnungen"
      end
    end

    context "without finance permissions" do
      it "does not render invoices tab" do
        get :index, params: {q: "bla"}

        expect(dom.all(:css, ".nav.nav-tabs")[0].text).to_not include "Rechnungen"
      end
    end

    context "with single invoice result" do
      before do
        allow_any_instance_of(FullTextController).to receive(:only_result).and_return(invoice)
      end

      let(:invoice) { invoices(:sent) }

      it "redirects to invoice view" do
        get :index, params: {q: "bla"}

        expect(response.headers["Location"]).not_to include "/api/"
        expect(response.headers["Location"]).to end_with "/invoices/#{invoice.id}"
      end
    end
  end
end
