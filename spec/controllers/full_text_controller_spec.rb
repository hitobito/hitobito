#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "spec_helper"

describe FullTextController, type: :controller do
  let(:current_user) { people(:top_leader) }

  before { sign_in(current_user) }

  before do
    [[:list_people, Person.where(id: people(:bottom_member).id)],
      [:query_people, Person.where(id: people(:bottom_member).id)],
      [:query_groups, Group.where(id: groups(:bottom_layer_one).id)],
      [:query_events, Event.where(id: events(:top_course).id)]]
  end

  describe "GET index" do
    it "finds person" do
      get :index, params: {q: "Bottom"}

      expect(assigns(:people)).to include(people(:bottom_member))
    end

    it "redirects to person if only finding a single person" do
      get :index, params: {q: "Bottom Member"}
      expect(response).to redirect_to(person_path(people(:bottom_member)))
    end

    it "finds group" do
      get :index, params: {q: groups(:bottom_layer_one).to_s[0..5]}

      expect(assigns(:groups)).to include(groups(:bottom_layer_one))
    end

    it "redirects to group if only finding a single group" do
      get :index, params: {q: groups(:bottom_layer_one).to_s}
      expect(response).to redirect_to(group_path(groups(:bottom_layer_one)))
    end

    it "finds event" do
      get :index, params: {q: events(:top_course).to_s[0..5]}

      expect(assigns(:events)).to include(events(:top_course))
    end

    it "redirects to event if only finding a single event" do
      get :index, params: {q: events(:top_course).to_s}
      expect(response).to redirect_to(event_path(events(:top_course)))
    end

    describe "invoices" do
      it "finds invoice" do
        get :index, params: {q: invoices(:invoice).title[0..5]}

        expect(assigns(:invoices)).to include(invoices(:invoice))
      end

      it "redirects to invoice if only finding a single invoice" do
        get :index, params: {q: invoices(:invoice).title}
        expect(response).to redirect_to(invoice_path(invoices(:invoice)))
      end

      context "when lacking finance permission" do
        let(:current_user) { Fabricate(Group::TopLayer::TopAdmin.sti_name, group: groups(:top_layer)).person }

        it "finds nothing when lacking finance permission" do
          get :index, params: {q: invoices(:invoice).title[0..5]}

          expect(assigns(:invoices)).to be_nil
        end
      end
    end

    context "without any params" do
      it "returns nothing" do
        get :index

        expect(@response).to be_ok
        expect(assigns(:people)).to eq([])
      end
    end

    context "json" do
      it "finds person" do
        get :index, params: {q: "Bottom"}, format: :json

        expect(@response.body).to include(people(:bottom_member).full_name)
      end

      it "finds groups" do
        get :index, params: {q: groups(:bottom_layer_one).to_s[0..5]}, format: :json

        expect(@response.body).to include(groups(:bottom_layer_one).to_s)
      end

      it "finds events" do
        get :index, params: {q: events(:top_course).to_s[0..5]}, format: :json

        expect(@response.body).to include(events(:top_course).to_s)
      end

      it "finds invoices" do
        get :index, params: {q: invoices(:invoice).title[0..5]}, format: :json

        expect(@response.body).to include(invoices(:invoice).title)
      end
    end
  end

  context "result tabs" do
    before do
      allow_any_instance_of(FullTextController).to receive(:only_result).and_return(nil)
    end

    it "displays people tab" do
      person_search_instance = instance_double(SearchStrategies::PersonSearch)
      allow(SearchStrategies::PersonSearch).to receive(:new).and_return(person_search_instance)
      allow(person_search_instance).to receive(:search_fulltext).and_return(Person.where(id: people(:bottom_member).id))

      get :index, params: {q: "query with people results"}
      expect(assigns(:active_tab)).to eq(:people)
    end

    it "displays groups tab" do
      group_search_instance = instance_double(SearchStrategies::GroupSearch)
      allow(SearchStrategies::GroupSearch).to receive(:new).and_return(group_search_instance)
      allow(group_search_instance).to receive(:search_fulltext)
        .and_return(Group.where(id: groups(:bottom_layer_one).id))

      get :index, params: {q: "query with group results"}
      expect(assigns(:active_tab)).to eq(:groups)
    end

    it "displays events tab" do
      event_search_instance = instance_double(SearchStrategies::EventSearch)
      allow(SearchStrategies::EventSearch).to receive(:new).and_return(event_search_instance)
      allow(event_search_instance).to receive(:search_fulltext).and_return(Event.where(id: events(:top_course).id))

      get :index, params: {q: "query with event results"}
      expect(assigns(:active_tab)).to eq(:events)
    end

    it "displays invoices tab" do
      invoice_search_instance = instance_double(SearchStrategies::InvoiceSearch)
      allow(SearchStrategies::InvoiceSearch).to receive(:new).and_return(invoice_search_instance)
      allow(invoice_search_instance).to receive(:search_fulltext).and_return(Invoice.where(id: invoices(:invoice).id))

      get :index, params: {q: "query with invoice results"}
      expect(assigns(:active_tab)).to eq(:invoices)
    end

    it "displays people tab by default" do
      get :index, params: {q: "query with no results"}
      expect(assigns(:active_tab)).to eq(:people)
    end
  end
end
