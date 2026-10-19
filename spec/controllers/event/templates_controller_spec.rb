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
        expect(dom).to have_css(%(a[href="#{edit_group_event_template_path(top_layer, template)}"]))
        expect(dom).to have_css(%(a[href="#{group_event_template_path(top_layer, template)}"]))
      end

      it "has new-template button per event type available to the group" do
        get :index, params: {group_id: top_layer.id}

        expect(dom).to have_css(
          %(a[href$="#{new_group_event_template_path(top_layer, event: {type: "Event"})}"]),
          text: "Anlass Vorlage erstellen"
        )
        expect(dom).to have_css(
          %(a[href$="#{new_group_event_template_path(top_layer, event: {type: "Event::Course"})}"]),
          text: "Kurs Vorlage erstellen"
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

  context "managing templates" do
    before { sign_in(top_leader) }

    describe "GET#new" do
      it "marks the new event as a template of the group" do
        get :new, params: {group_id: top_layer.id, event: {type: "Event"}}

        event = assigns(:event)
        expect(event.template).to eq true
        expect(event.groups).to eq [top_layer]
        expect(event.dates).to be_empty
      end
    end

    describe "POST#create" do
      it "creates a template without dates, and redirects to the templates index" do
        post :create, params: {
          group_id: top_layer.id,
          event: {type: "Event", name: "Vorlage ohne Datum", inherit: "1"}
        }

        event = assigns(:event)
        expect(event).to be_persisted
        expect(event.template).to eq true
        expect(event.inherit).to eq true
        expect(event.groups).to eq [top_layer]
        expect(response).to redirect_to(group_event_templates_path(top_layer))
      end

      it "collapses a multi-group source event to a single group" do
        Fabricate(Group::BottomLayer::Leader.sti_name, group: bottom_layer_one, person: top_leader)
        source = Fabricate(:event, groups: [bottom_layer_one, groups(:bottom_layer_two)])

        post :create, params: {
          group_id: bottom_layer_one.id,
          source_id: source.id,
          event: {name: "Vorlage von Multi-Gruppen-Event"}
        }

        event = assigns(:event)
        expect(event).to be_persisted
        expect(event.template).to eq true
        expect(event.groups).to eq [bottom_layer_one]
      end
    end

    describe "PUT#update" do
      it "updates name and inherit flag, and redirects to the templates index" do
        put :update, params: {
          group_id: top_layer.id, id: template.id, event: {name: "Renamed", inherit: "1"}
        }

        expect(template.reload.name).to eq("Renamed")
        expect(template.inherit).to eq true
        expect(response).to redirect_to(group_event_templates_path(top_layer))
      end

      it "raises 404 for a normal event" do
        expect do
          put :update, params: {group_id: top_layer.id, id: events(:top_event).id, event: {name: "X"}}
        end.to raise_error(ActiveRecord::RecordNotFound)
      end
    end

    describe "DELETE#destroy" do
      it "destroys and redirects to the templates index" do
        expect do
          delete :destroy, params: {group_id: top_layer.id, id: template.id}
        end.to change { Event.templates.count }.by(-1)

        expect(response).to redirect_to(group_event_templates_path(top_layer))
      end
    end

    describe "forms" do
      render_views

      let(:dom) { Capybara::Node::Simple.new(response.body) }

      it "posts the new form to the templates path and cancels to the index" do
        get :new, params: {group_id: top_layer.id, event: {type: "Event"}}

        expect(dom).to have_css(%(form[action="#{group_event_templates_path(top_layer)}"]))
        expect(dom).to have_css(%(a.link.cancel[href="#{group_event_templates_path(top_layer)}"]))
      end

      it "patches the edit form to the template path and cancels to the index" do
        get :edit, params: {group_id: top_layer.id, id: template.id}

        expect(dom).to have_css(%(form[action="#{group_event_template_path(top_layer, template)}"]))
        expect(dom).to have_css(%(a.link.cancel[href="#{group_event_templates_path(top_layer)}"]))
      end
    end
  end

  context "authorization" do
    it "denies managing templates with group_and_below_full on the layer group" do
      sign_in(Fabricate(Group::TopLayer::TopAdmin.sti_name, group: top_layer).person)

      expect do
        get :new, params: {group_id: top_layer.id, event: {type: "Event"}}
      end.to raise_error(CanCan::AccessDenied)
      expect do
        get :edit, params: {group_id: top_layer.id, id: template.id}
      end.to raise_error(CanCan::AccessDenied)
    end

    it "permits managing templates with layer_full in the same layer" do
      sign_in(Fabricate(Group::BottomLayer::LocalGuide.sti_name, group: bottom_layer_one).person)

      post :create, params: {group_id: bottom_layer_one.id, event: {type: "Event", name: "Vorlage"}}

      expect(assigns(:event)).to be_persisted
      expect(assigns(:event).groups).to eq [bottom_layer_one]
    end
  end
end
