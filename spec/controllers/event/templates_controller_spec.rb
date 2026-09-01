# frozen_string_literal: true

#  Copyright (c) 2026, Hitobito AG. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "spec_helper"

describe Event::TemplatesController do
  let(:top_layer) { groups(:top_layer) }
  let(:bottom_layer_one) { groups(:bottom_layer_one) }
  let(:template) { events(:template) }
  let(:top_leader) { people(:top_leader) }

  describe "GET#index" do
    before { sign_in(top_leader) }

    it "lists templates of the group when signed in as admin" do
      get :index, params: {group_id: top_layer.id}

      expect(response).to be_successful
      expect(assigns(:events)).to eq [template]
    end

    it "does not list templates of another group" do
      other_group_template = Fabricate(:event, groups: [bottom_layer_one], template: true)

      get :index, params: {group_id: top_layer.id}

      expect(assigns(:events)).not_to include(other_group_template)
    end

    it "raises access denied when not permitted" do
      sign_in(people(:bottom_member))

      expect { get :index, params: {group_id: top_layer.id} }.to raise_error(CanCan::AccessDenied)
    end

    context "with views" do
      render_views

      let(:dom) { Capybara::Node::Simple.new(response.body) }

      it "has edit and destroy action links" do
        get :index, params: {group_id: top_layer.id}
        expect(dom).to have_css(%(a[href="#{edit_group_event_path(top_layer, template)}"]))
        expect(dom).to have_css(%(a[href="#{group_event_path(top_layer, template)}"]))
      end

      it "has new-template button per event type available to the group" do
        get :index, params: {group_id: top_layer.id}

        expect(dom).to have_css(
          %(a[href$="#{new_group_event_path(top_layer, event: {type: "Event", template: true})}"]),
          text: "Anlass-Vorlage erstellen"
        )
        expect(dom).to have_css(
          %(a[href$="#{new_group_event_path(top_layer, event: {type: "Event::Course", template: true})}"]),
          text: "Kurs-Vorlage erstellen"
        )
      end

      it "renders the group sheet with a breadcrumb back to the group" do
        Fabricate(Group::BottomLayer::Leader.name.to_sym, person: top_leader, group: bottom_layer_one)
        get :index, params: {group_id: bottom_layer_one.id}

        expect(dom).to have_css(".sheet.parent .breadcrumb", text: bottom_layer_one.parent.name)
        expect(dom).to have_css(".level.active", text: bottom_layer_one.name)
      end
    end

    context "sorting" do
      before do
        template.update!(name: "Zebra")
        Fabricate(:course, groups: [top_layer], template: true, name: "Anton")
      end

      it "sorts by name" do
        get :index, params: {group_id: top_layer.id, sort: :name, sort_dir: :asc}
        expect(assigns(:events).map(&:name)).to eq ["Anton", "Zebra"]

        get :index, params: {group_id: top_layer.id, sort: :name, sort_dir: :desc}
        expect(assigns(:events).map(&:name)).to eq ["Zebra", "Anton"]
      end

      it "sorts by the translated type label, not the raw type column value" do
        get :index, params: {group_id: top_layer.id, sort: :type, sort_dir: :asc}
        expect(assigns(:events).map { |e| e.model.class }).to eq [Event, Event::Course]

        get :index, params: {group_id: top_layer.id, sort: :type, sort_dir: :desc}
        expect(assigns(:events).map { |e| e.model.class }).to eq [Event::Course, Event]
      end
    end
  end
end
