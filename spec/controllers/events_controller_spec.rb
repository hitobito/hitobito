# frozen_string_literal: true

#  Copyright (c) 2012-2020, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "spec_helper"

describe EventsController do
  let(:group) { groups(:top_group) }
  let(:group2) { Fabricate(Group::TopGroup.name.to_sym, name: "CCC", parent: groups(:top_layer)) }
  let(:group3) { Fabricate(Group::TopGroup.name.to_sym, name: "AAA", parent: groups(:top_layer)) }

  context "event_course" do
    before { group2 }

    context "GET index" do
      let(:group) { groups(:top_layer) }
      let(:top_leader) { people(:top_leader) }

      before do
        sign_in(top_leader)
        @g1 = Fabricate(Group::TopGroup.name.to_sym, name: "g1", parent: groups(:top_group))
        @e1 = Fabricate(:event, groups: [@g1])
        Fabricate(:event, groups: [groups(:bottom_group_one_one)])
      end

      it "does page correctly even if event have multiple dates" do
        expect(Kaminari.config).to receive(:default_per_page).and_return(2).at_least(:once)
        events(:top_event).dates.create!(start_at: "2012-3-02")
        get :index, params: {group_id: group.id, year: 2012, filter: "all"}
        expect(assigns(:events)).to have(2).entries
      end

      it "does show the last filled page if page-number is too high" do
        expect(Kaminari.config).to receive(:default_per_page).and_return(2).at_least(:once)

        # there are 3 events, with the paging-limit of 2, the pages 1 and 2 are
        # filled, page 42 is not

        get :index, params: {group_id: group.id, year: 2012, filter: "all", page: 42}
        expect(assigns(:events)).to have(1).entries
      end

      it "lists events of descendant groups by default" do
        get :index, params: {group_id: group.id, year: 2012}
        expect(assigns(:events)).to have(3).entries
      end

      it "limits list to events of all non layer descendants" do
        get :index, params: {group_id: group.id, filter: "layer", year: 2012}
        expect(assigns(:events)).to have(2).entries
      end

      it "orders according to sort expression" do
        get :index, params: {group_id: group.id, filter: "layer", year: 2012,
                             sort: :name, sort_dir: :asc,}
        expect(assigns(:events).first.name).to eq "Eventus"
      end

      it "sets cookie on export" do
        get :index, params: {group_id: group.id}, format: :csv

        cookie = JSON.parse(cookies[Cookies::AsyncDownload::NAME])

        expect(cookie[0]["name"]).to match(/^(events_export)+\S*(#{top_leader.id})+$/)
        expect(cookie[0]["type"]).to match(/^csv$/)
        expect(response).to redirect_to(returning: true)
      end

      it "renders json with dates" do
        Fabricate(:event_date, event: @e1)
        get :index, params: {group_id: @g1}, format: :json
        json = JSON.parse(@response.body)

        event = json["events"].find { |e| e["id"] == @e1.id.to_s }
        expect(event["name"]).to eq("Eventus")
        expect(event["links"]["dates"].size).to eq(2)
        expect(event["links"]["groups"].size).to eq(1)

        expect(json["current_page"]).to eq(1)
        expect(json["total_pages"]).to eq(1)
        expect(json["prev_page_link"]).to be_nil
        expect(json["next_page_link"]).to be_nil
      end

      it "renders json pagination first page" do
        5.times { Fabricate(:event_date, event: Fabricate(:event, groups: [@g1])) }

        relation = Event.const_get(:ActiveRecord_Relation)
        allow_any_instance_of(relation)
          .to receive(:page).with(nil).and_return(Event.with_group_id([@g1]).page(1).per(3))

        get :index, params: {group_id: @g1}, format: :json
        json = JSON.parse(@response.body)

        expect(json["events"].count).to eq(3)

        expect(json["current_page"]).to eq(1)
        expect(json["total_pages"]).to eq(2)
        expect(json["prev_page_link"]).to be_nil
        expect(json["next_page_link"]).to eq controller.url_for(request.params.merge(page: 2))
      end

      it "renders json pagination second page" do
        5.times { Fabricate(:event_date, event: Fabricate(:event, groups: [@g1])) }

        relation = Event.const_get(:ActiveRecord_Relation)
        allow_any_instance_of(relation)
          .to receive(:page).with("2").and_return(Event.with_group_id([@g1]).page(2).per(3))

        get :index, params: {group_id: @g1, page: 2}, format: :json
        json = JSON.parse(@response.body)

        expect(json["events"].count).to eq(3)

        expect(json["current_page"]).to eq(2)
        expect(json["total_pages"]).to eq(2)
        expect(json["prev_page_link"]).to eq controller.url_for(request.params.merge(page: 1))
        expect(json["next_page_link"]).to be_nil
      end
    end

    context "GET show" do
      it "sets empty @user_participation" do
        sign_in(people(:top_leader))

        get :show, params: {group_id: groups(:top_layer).id, id: events(:top_event)}

        expect(assigns(:user_participation)).to be_nil
      end

      it "sets  @user_participation" do
        p = Fabricate(:event_participation, event: events(:top_event), person: people(:top_leader))
        sign_in(people(:top_leader))

        get :show, params: {group_id: groups(:top_layer).id, id: events(:top_event)}

        expect(assigns(:user_participation)).to eq(p)
      end

      it "renders json" do
        sign_in(people(:top_leader))

        get :show, params: {group_id: groups(:top_layer), id: events(:top_event)}, format: :json
        json = JSON.parse(@response.body)

        event = json["events"].find { |e| e["id"] == events(:top_event).id.to_s }
        expect(event["name"]).to eq("Top Event")
        expect(event["links"]["dates"].size).to eq(1)
      end
    end

    context "GET new" do
      it "loads sister groups" do
        sign_in(people(:top_leader))
        group3

        get :new, params: {group_id: group.id, event: {type: "Event"}}

        expect(assigns(:groups)).to eq([group3, group2])
      end

      it "does not load deleted kinds" do
        sign_in(people(:top_leader))

        get :new, params: {group_id: group.id, event: {type: "Event::Course"}}
        expect(assigns(:kinds)).not_to include event_kinds(:old)
      end

      it "duplicates other course" do
        sign_in(people(:top_leader))
        source = events(:top_course)

        get :new, params: {group_id: source.groups.first.id, source_id: source.id}

        event = assigns(:event)
        expect(event.state).to be_nil
        expect(event.name).to eq(source.name)
        expect(event.kind_id).to eq(source.kind_id)
        expect(event.application_questions.map(&:question)).to match_array(
          source.application_questions.map(&:question)
        )
        expect(event.application_questions.map(&:id).uniq).to eq([nil])
      end

      it "raises not found if event is in other group" do
        sign_in(people(:top_leader))

        expect {
          get :new, params: {group_id: group.id, source_id: events(:top_course).id}
        }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end

    context "POST create" do
      let(:date) do
        {label: "foo", start_at_date: Time.zone.today, finish_at_date: Time.zone.today}
      end
      let(:question) { {question: "foo?", choices: "1,2,3,4"} }

      it "creates new event course with dates" do
        sign_in(people(:top_leader))

        post :create, params: {
          event: {group_ids: [group.id, group2.id],
                  name: "foo",
                  kind_id: event_kinds(:slk).id,
                  dates_attributes: [date],
                  application_questions_attributes: [question],
                  contact_id: people(:top_leader).id,
                  type: "Event::Course",},
          group_id: group.id,
        }

        event = assigns(:event)
        is_expected.to redirect_to(group_event_path(group, event))
        expect(event).to be_persisted
        expect(event.dates.size).to eq(1)
        expect(event.dates.first).to be_persisted
        expect(event.questions.size).to eq(1)
        expect(event.questions.first).to be_persisted

        expect(event.group_ids).to match_array([group.id, group2.id])
      end

      it "does not create event course if the user hasn't permission" do
        user = Fabricate(Group::BottomGroup::Leader.name.to_s, group: groups(:bottom_group_one_one))
        sign_in(user.person)

        expect {
          post :create, params: {
            event: {group_id: group.id,
                    name: "foo",
                    type: "Event::Course",},
            group_id: group.id,
          }
        }.to raise_error(CanCan::AccessDenied)
      end
    end

    context "PUT update" do
      let(:group) { groups(:top_layer) }
      let(:event) { events(:top_event) }

      before { sign_in(people(:top_leader)) }

      it "creates, updates and destroys dates" do
        d1 = event.dates.create!(label: "Pre",
                                 start_at_date: "1.1.2014", finish_at_date: "3.1.2014")
        d2 = event.dates.create!(label: "Main",
                                 start_at_date: "1.2.2014", finish_at_date: "7.2.2014")

        expect {
          put :update, params: {
            group_id: group.id,
            id: event.id,
            event: {name: "testevent",
                    dates_attributes: {
                      d1.id.to_s => {id: d1.id,
                                     label: "Vorweek",
                                     start_at_date: "3.1.2014",
                                     finish_at_date: "4.1.2014",},
                      d2.id.to_s => {id: d2.id, _destroy: true},
                      "999" => {label: "Nachweek",
                                start_at_date: "3.2.2014",
                                finish_at_date: "5.2.2014",},
                    },},
          }
          expect(assigns(:event)).to be_valid
        }.not_to(change { Event::Date.count })

        expect(event.reload.name).to eq "testevent"
        dates = event.dates.order(:start_at)
        expect(dates.size).to eq(3)
        first = dates.second
        expect(first.label).to eq "Vorweek"
        expect(first.start_at_date).to eq Date.new(2014, 1, 3)
        expect(first.finish_at_date).to eq Date.new(2014, 1, 4)
        second = dates.third
        expect(second.label).to eq "Nachweek"
        expect(second.start_at_date).to eq Date.new(2014, 2, 3)
        expect(second.finish_at_date).to eq Date.new(2014, 2, 5)
      end

      it "creates, updates and destroys questions" do
        q1 = event.questions.create!(question: "Who?")
        q2 = event.questions.create!(question: "What?")
        q3 = event.questions.create!(question: "Payed?", admin: true)

        expect {
          put :update, params: {
            group_id: group.id,
            id: event.id,
            event: {
              name: "testevent",
              application_questions_attributes: {
                q1.id.to_s => {id: q1.id, question: "Whoo?"},
                q2.id.to_s => {id: q2.id, _destroy: true},
                "999" => {question: "How much?", choices: "1,2,3"},
              },
              admin_questions_attributes: {
                q3.id.to_s => {id: q3.id, _destroy: true},
                "999" => {question: "Powned?", choices: "ja, nein"},
              },
            },
          }
          expect(assigns(:event)).to be_valid
        }.not_to(change { Event::Question.count })

        expect(event.reload.name).to eq "testevent"
        questions = event.questions.order(:question)
        expect(questions.size).to eq(3)
        first = questions.first
        expect(first.question).to eq "How much?"
        expect(first.choices).to eq "1,2,3"
        second = questions.second
        expect(second.question).to eq "Powned?"
        expect(second.admin).to eq true
        third = questions.third
        expect(third.question).to eq "Whoo?"
        expect(third.admin).to eq false
      end
    end
  end

  context "destroyed associations" do
    let(:course) { Fabricate(:course, groups: [group, group2, group3]) }

    before do
      course
      sign_in(people(:top_leader))
    end

    context "kind" do
      before { course.kind.destroy }

      it "new does not include delted kind" do
        get :new, params: {group_id: group.id, event: {type: "Event::Course"}}
        expect(assigns(:kinds)).not_to include(course.reload.kind)
      end

      it "edit does include deleted kind" do
        get :edit, params: {group_id: group.id, id: course.id}
        expect(assigns(:kinds)).to include(course.reload.kind)
      end
    end

    context "groups" do
      before { group3.destroy }

      it "new does not include delete" do
        get :new, params: {group_id: group.id, event: {type: "Event::Course"}}
        expect(assigns(:groups)).not_to include(group3)
      end

      it "edit does include delete" do
        get :edit, params: {group_id: group.id, id: course.id}
        expect(assigns(:groups)).to include(group3)
      end
    end
  end

  context "contact attributes" do
    let(:event) { events(:top_event) }
    let(:group) { groups(:top_layer) }

    before { sign_in(people(:top_leader)) }

    it "assigns required and hidden contact attributes" do
      put :update, params: {group_id: group.id, id: event.id,
                            event: {contact_attrs: {nickname: :required,
                                                    address: :hidden,
                                                    social_accounts: :hidden,}},}

      expect(event.reload.required_contact_attrs).to include("nickname")
      expect(event.reload.hidden_contact_attrs).to include("address")
      expect(event.reload.hidden_contact_attrs).to include("social_accounts")
    end

    it "removes contact attributes" do
      event.update!({hidden_contact_attrs: %w[social_accounts address nickname]})

      put :update, params: {group_id: group.id, id: event.id,
                            event: {contact_attrs: {nickname: :hidden}},}

      expect(event.reload.hidden_contact_attrs).to include("nickname")
      expect(event.hidden_contact_attrs).not_to include("address")
      expect(event.hidden_contact_attrs).not_to include("social_accounts")
    end
  end

  describe "token authenticated" do
    let(:event) { events(:top_event) }
    let(:group) { groups(:top_layer) }

    describe "GET index" do
      it "indexes page when token is valid" do
        get :index, params: {group_id: group.id, token: "PermittedToken"}
        is_expected.to render_template("index")
      end

      it "does not show page for unpermitted token" do
        expect {
          get :index, params: {group_id: group.id, token: "RejectedToken"}
        }.to raise_error(CanCan::AccessDenied)
      end
    end

    describe "GET show" do
      it "shows page when token is valid" do
        get :show, params: {group_id: group.id, id: event, token: "PermittedToken"}
        is_expected.to render_template("show")
      end

      it "does not show page for unpermitted token" do
        expect {
          get :show, params: {group_id: group.id, id: event, token: "RejectedToken"}
        }.to raise_error(CanCan::AccessDenied)
      end
    end
  end

  describe "with valid OAuth token" do
    let(:event) { events(:top_event) }
    let(:group) { groups(:top_layer) }
    let(:token) { instance_double("Doorkeeper::AccessToken", acceptable?: true, accessible?: true, resource_owner_id: people(:top_leader).id) }

    before do
      allow(controller).to receive(:doorkeeper_token) { token }
    end

    it "GET index indexes page" do
      get :index, params: {group_id: group.id}
      is_expected.to render_template("index")
    end

    it "GET show shows page when token is valid" do
      get :show, params: {group_id: group.id, id: event}
      is_expected.to render_template("show")
    end
  end

  describe "with invalid OAuth token (expired or revoked)" do
    let(:event) { events(:top_event) }
    let(:group) { groups(:top_layer) }
    let(:token) { instance_double("Doorkeeper::AccessToken", acceptable?: true, accessible?: false, resource_owner_id: people(:top_leader).id) }

    before do
      allow(controller).to receive(:doorkeeper_token) { token }
    end

    it "GET index redirects to login" do
      get :index, params: {group_id: group.id}
      is_expected.to redirect_to("http://test.host/users/sign_in")
    end

    it "GET show redirects to login" do
      get :show, params: {group_id: group.id, id: event}
      is_expected.to redirect_to("http://test.host/users/sign_in")
    end
  end

  describe "without acceptable OAuth token (missing scope)" do
    let(:event) { events(:top_event) }
    let(:group) { groups(:top_layer) }
    let(:token) { instance_double("Doorkeeper::AccessToken", acceptable?: false, accessible?: true, resource_owner_id: people(:top_leader).id) }

    before do
      allow(controller).to receive(:doorkeeper_token) { token }
    end

    it "GET index fails with HTTP 403 (forbidden)" do
      get :index, params: {group_id: group.id}
      expect(response).to have_http_status(:forbidden)
    end

    it "GET show fails with HTTP 403 (forbidden)" do
      get :show, params: {group_id: group.id, id: event}
      expect(response).to have_http_status(:forbidden)
    end
  end

  describe "default scope" do
    let(:top_layer) { groups(:top_layer) }

    context "token" do
      it "in current year" do
        get :index, params: {group_id: top_layer.id, token: "PermittedToken"}
        expect(assigns(:events)).to be_empty
      end

      it "in 2012" do
        get :index, params: {group_id: top_layer.id, year: 2012, token: "PermittedToken"}
        expect(assigns(:events)).to have(1).entries
      end
    end

    context "oauth" do
      let(:token) { instance_double("Doorkeeper::AccessToken", acceptable?: true, accessible?: true, resource_owner_id: people(:top_leader).id) }

      before do
        allow(controller).to receive(:doorkeeper_token) { token }
      end

      it "in current year" do
        get :index, params: {group_id: top_layer.id}
        expect(assigns(:events)).to be_empty
      end

      it "in 2012" do
        get :index, params: {group_id: top_layer.id, year: 2012}
        expect(assigns(:events)).to have(1).entries
      end
    end

    context "html" do
      before { sign_in(people(:top_leader)) }

      it "in current year" do
        get :index, params: {group_id: top_layer.id}
        expect(assigns(:events)).to be_empty
      end

      it "in 2012" do
        get :index, params: {group_id: top_layer.id, year: 2012}
        expect(assigns(:events)).to have(1).entries
      end
    end
  end
end
