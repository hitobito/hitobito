# encoding: utf-8

#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

# encoding:  utf-8

require "spec_helper"

describe PeopleController, type: :controller do
  let(:top_leader) { people(:top_leader) }
  let(:top_group) { groups(:top_group) }
  let(:bottom_group) { groups(:bottom_group_one_one) }
  let(:test_entry) { top_leader }
  let(:test_entry_attrs) { {first_name: "foo", last_name: "bar"} }
  let(:other) { Fabricate(Group::TopGroup::Member.name.to_sym, group: top_group).person }
  let(:dom) { Capybara::Node::Simple.new(response.body) }

  before { sign_in(top_leader) }

  def scope_params
    return {group_id: top_group.id} unless RSpec.current_example.metadata[:action] == :new
    {group_id: top_group.id, role: {type: "Group::TopGroup::Member", group_id: top_group.id}}
  end

  include_examples "crud controller", skip: [%w(new), %w(create), %w(destroy)]

  describe "#show" do
    let(:page_content) { ["Bearbeiten", "Info", "Verlauf", "Aktive Rollen", "Passwort ändern"] }

    it "cannot view person in uppper group" do
      sign_in(Fabricate(Group::BottomGroup::Leader.name.to_sym, group: bottom_group).person)
      expect do
        get :show, params: {group_id: top_group.id, id: top_leader.id}
      end.to raise_error(CanCan::AccessDenied)
    end

    it "renders my own page" do
      get :show, params: {group_id: top_group.id, id: top_leader.id}
      page_content.each { |text| expect(response.body).to match(/#{text}/) }
    end

    it "renders page of other group member" do
      sign_in(Fabricate(Group::TopGroup::Member.name.to_sym, group: top_group).person)
      get :show, params: {group_id: top_group.id, id: other.id}
      page_content.grep(/Info/).each { |text| expect(response.body).to match(/#{text}/) }
      page_content.grep(/[^Info]/).each { |text| expect(response.body).not_to match(/#{text}/) }
      expect(dom).not_to have_selector('a[data-method="delete"] i.fa-trash-alt')
    end

    it "leader can see link to remove role" do
      get :show, params: {group_id: top_group.id, id: other.id}
      expect(dom).to have_selector('a[data-method="delete"] i.fa-trash-alt')
    end

    it "leader can see created and updated info" do
      sign_in(top_leader)
      get :show, params: {group_id: top_group.id, id: other.id}
      expect(dom).to have_selector("dt", text: "Erstellt")
      expect(dom).to have_selector("dt", text: "Geändert")
    end

    it "member without permission to see details cannot see created or updated info" do
      person1 = (Fabricate(Group::BottomLayer::Leader.name.to_sym, group: groups(:bottom_layer_one)).person)
      person2 = (Fabricate(Group::TopGroup::Secretary.name.to_sym, group: groups(:top_group)).person)
      sign_in(person1)
      get :show, params: {group_id: person2.primary_group_id, id: person2}
      expect(dom).not_to have_selector("dt", text: "Erstellt")
      expect(dom).not_to have_selector("dt", text: "Geändert")
    end

    context "send_login tooltip" do
      before { sign_in(top_leader) }

      def tooltip_includes(text)
        expect(dom.all(".btn[rel^=tooltip]")[0][:title]).to include(text)
      end

      it "should hint for persons without login and token" do
        get :show, params: {group_id: top_group.id, id: other.id}
        tooltip_includes("sendet ihr einen Link")
      end

      it "should hint for persons without login but with token" do
        other.generate_reset_password_token!
        get :show, params: {group_id: top_group.id, id: other.id}
        tooltip_includes("sendet ihr den Link erneut")
      end

      it "should hint for persons with login" do
        other.password = "123456"
        other.save!
        get :show, params: {group_id: top_group.id, id: other.id}
        tooltip_includes("sendet ihr einen Link, damit sie ihr Passwort neu setzen kann")
      end
    end
  end

  describe "role section" do
    let(:params) { {group_id: top_group.id, id: top_leader.id} }
    let(:section) { dom.all("aside section")[1] }

    it "contains roles" do
      get :show, params: params
      expect(section.find("h2").text).to eq "Aktive Rollen"
      expect(section.all("tr").first.text).to include("TopGroup")
      expect(section).to have_css(".btn-small")
      expect(section.find("tr:eq(1) table tr:eq(1)").text).to include("Leader")
      edit_role_path = edit_group_role_path(top_group, top_leader.roles.first)
      expect(section.find("tr:eq(1) table tr:eq(1) td:eq(2)").native.to_xml).to include edit_role_path
    end
  end

  describe "add requests section" do
    let(:section) { dom.all("aside section")[2] }

    it "contains requests" do
      r1 = Person::AddRequest::Group.create!(
        person: top_leader,
        requester: Fabricate(:person),
        body: groups(:bottom_layer_one),
        role_type: Group::BottomLayer::Member.sti_name)
      r2 = Person::AddRequest::Event.create!(
        person: top_leader,
        requester: Fabricate(:person),
        body: events(:top_course),
        role_type: Event::Role::Cook.sti_name)
      r3 = Person::AddRequest::MailingList.create!(
        person: top_leader,
        requester: Fabricate(:person),
        body: mailing_lists(:leaders))
      get :show, params: {group_id: top_group.id, id: top_leader.id}

      expect(section.find("h2").text).to eq "Anfragen"
      expect(section.all("tr")[0].text).to include("Bottom Layer Bottom One")
      expect(section.all("tr")[1].text).to include("Kurs Top Course")
      expect(section.all("tr")[2].text).to include("Abo Leaders")
    end

    it "is hidden if no pending requests exist" do
      Person::AddRequest::Group.create!(
        person: Fabricate(:person),
        requester: Fabricate(:person),
        body: groups(:bottom_layer_one),
        role_type: Group::BottomLayer::Member.sti_name)
      get :show, params: {group_id: top_group.id, id: top_leader.id}

      expect(section.find("h2").text).to eq "Qualifikationen Erstellen"
    end
  end

  describe "event sections" do
    let(:params) { {group_id: top_group.id, id: top_leader.id} }
    let(:header) { section.find("h2").text.strip }
    let(:dates) { section.find("tr:eq(1) td:eq(2)").text.strip }
    let(:label) { section.find("tr:eq(1) td:eq(1)") }
    let(:label_link) { label.find("a") }
    let(:course) { Fabricate(:course, groups: [groups(:top_layer)], kind: event_kinds(:slk)) }

    context "pending applications" do
      let(:section) { dom.all("aside section")[2] }
      let(:date) { 1.week.from_now.to_date }

      it "is missing if we have no applications" do
        get :show, params: params
        expect(dom).to have_css("aside section", count: 3) # only tags, roles and qualification
      end

      it "lists application" do
        appl = create_application(date)
        get :show, params: params
        expect(header).to eq "Anmeldungen"
        expect(label_link[:href]).to eq "/groups/#{course.group_ids.first}/events/#{course.id}/participations/#{appl.participation.id}"
        expect(label_link.text).to match(/Eventus/)
        expect(label.text).to match(/Top/)
        expect(dates).to eq "#{I18n.l(date)} - #{I18n.l(date + 5.days)}"
      end
    end

    context "upcoming events" do
      let(:section) { dom.all("aside section")[2] }
      let(:date) { 2.days.from_now }
      let(:pretty_date) { date.strftime("%d.%m.%Y %H:%M") + " - " + (date + 5.days).strftime("%d.%m.%Y %H:%M") }

      it "is missing if we have no events" do
        get :show, params: params
        expect(dom).to have_css("aside section", count: 3) # only tags, roles and qualification
      end

      it "is missing if we have no upcoming events" do
        create_participation(10.days.ago, true)
        get :show, params: params
        expect(dom).to have_css("aside section", count: 3) # only tags, roles and qualification
      end

      it "lists event label, link and dates" do
        create_participation(date, true)
        get :show, params: params
        expect(header).to eq "Meine nächsten Anlässe"
        expect(label_link[:href]).to eq group_event_path(course.groups.first, course)
        expect(label_link.text).to eq "Eventus"
        expect(label.text).to match(/Top/)
        expect(dates).to eq pretty_date
      end
    end

    def create_application(date)
      Fabricate(:event_application, priority_1: course, participation: create_participation(date, false))
    end

    def create_participation(date, active_participation = false)
      set_start_finish(course, date, date + 5.days)
      Fabricate(:event_participation, person: top_leader, event: course, active: active_participation)
    end
  end

  describe_action :put, :update, id: true do
    let(:params) { {person: {birthday: "33.33.33"}} }

    it "displays old value again" do
      is_expected.to render_template("edit")
      expect(dom).to have_selector('.error input[value="33.33.33"]')
    end
  end

  describe "redirect_url" do
    it "should adjust url if param redirect_url is given" do
      get :edit, params: {
        group_id: top_group.id,
        id: top_leader.id,
        return_url: "foo"
      }

      expect(dom.all("a", text: "Abbrechen").first[:href]).to eq "foo"
      expect(dom.find("input#return_url", visible: false).value).to eq "foo"
    end
  end
end
