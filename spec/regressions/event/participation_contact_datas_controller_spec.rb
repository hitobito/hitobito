#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

# encoding:  utf-8

require "spec_helper"

describe Event::ParticipationContactDatasController, type: :controller do
  render_views

  let(:group) { groups(:top_layer) }
  let(:course) { Fabricate(:course, groups: [group]) }
  let(:person) { people(:top_leader) }
  let(:dom) { Capybara::Node::Simple.new(response.body) }

  before { sign_in(person) }

  describe "GET edit" do
    it "does not show hidden contact fields" do
      course.update!({hidden_contact_attrs: ["address", "nickname", "social_accounts"]})

      get :edit, params: {group_id: course.groups.first.id, event_id: course.id, event_role: {type: "Event::Course::Role::Participant"}}

      expect(dom).to have_selector("input#event_participation_contact_data_first_name")
      expect(dom).to have_selector("input#event_participation_contact_data_last_name")
      expect(dom).to have_selector("input#event_participation_contact_data_email")
      expect(dom).to have_selector("#additional_emails_fields")
      expect(dom).to have_selector("#phone_numbers_fields")

      expect(dom).to have_no_selector("textarea#event_participation_contact_data_address")
      expect(dom).to have_no_selector("input#event_participation_contact_data_nickname")
      expect(dom).to have_no_selector("#social_accounts_fields")
    end

    it "shows all contact fields by default" do
      get :edit, params: {group_id: course.groups.first.id, event_id: course.id, event_role: {type: "Event::Course::Role::Participant"}}

      contact_attrs = [:first_name, :last_name, :nickname,
                       :company_name, :zip_code, :town,
                       :gender_w, :gender_m, :gender_,
                       :birthday, :email,]

      contact_attrs.each do |a|
        expect(dom).to have_selector("input#event_participation_contact_data_#{a}")
      end

      expect(dom).to have_selector("textarea#event_participation_contact_data_address")

      expect(dom).to have_selector("#additional_emails_fields")
      expect(dom).to have_selector("#phone_numbers_fields")
      expect(dom).to have_selector("#social_accounts_fields")
    end

    it "marks required attributes with an asterisk" do
      course.update!({required_contact_attrs: ["address", "nickname"]})

      get :edit, params: {group_id: course.groups.first.id, event_id: course.id, event_role: {type: "Event::Course::Role::Participant"}}
    end
  end

  context "POST update" do
    before do
      course.update!({required_contact_attrs: ["nickname", "address"]})
    end

    it "validates contact attributes and person attributes" do
      contact_data_params = {first_name: "Hans", last_name: "Gugger", email: "invalid", nickname: ""}

      post :update, params: {group_id: group.id, event_id: course.id, event_participation_contact_data: contact_data_params, event_role: {type: "Event::Course::Role::Participant"}}

      is_expected.to render_template(:edit)

      expect(dom).to have_selector(".alert-error li", text: "Übername muss ausgefüllt werden")
      expect(dom).to have_selector(".alert-error li", text: "Adresse muss ausgefüllt werden")
      expect(dom).to have_selector(".alert-error li", text: /Haupt-E-Mail ist nicht gültig/)
    end

    it "updates person attributes and redirects to event questions" do
      contact_data_params = {first_name: "Hans", last_name: "Gugger",
                             email: "dude@example.com", nickname: "Jojo",
                             address: "Street 33",}

      post :update, params: {group_id: group.id, event_id: course.id, event_participation_contact_data: contact_data_params, event_role: {type: "Event::Course::Role::Participant"}}

      is_expected.to redirect_to new_group_event_participation_path(group,
        course,
        event_role: {type: "Event::Course::Role::Participant"})

      person.reload
      expect(person.nickname).to eq("Jojo")
      expect(person.email).to eq("dude@example.com")
    end
  end
end
