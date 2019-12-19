# encoding: utf-8

#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require 'spec_helper'

describe Event::ParticipationsController, type: :controller do

  # always use fixtures with crud controller examples, otherwise request reuse might produce errors
  let(:test_entry) { event_participations(:top) }

  let(:course) { test_entry.event }
  let(:group)  { course.groups.first }
  let(:event_base) { Fabricate(:event) }

  let(:test_entry_attrs) do
    {
      additional_information: 'blalbalbalsbla',
      answers_attributes: [
        { answer: 'Halbtax', question_id: event_questions(:top_ov).id },
        { answer: 'nein',    question_id: event_questions(:top_vegi).id },
        { answer: 'Ne du',   question_id: event_questions(:top_more).id }
      ]
    }
  end

  def scope_params
    { group_id: group.id, event_id: course.id }
  end

  before do
    user = people(:top_leader)
    user.qualifications << Fabricate(:qualification, qualification_kind: qualification_kinds(:gl),
                                                     start_at: course.dates.first.start_at)
    sign_in(user)
  end

  include_examples 'crud controller', skip: [%w(destroy)]

  describe_action :get, :show, id: true, perform_request: false do
    let(:user) { test_entry.person }
    let(:contact) { Fabricate(:person_with_address) }
    let(:application) do
      Fabricate(:event_application, priority_1: test_entry.event, participation: test_entry)
    end

    let(:dom) { Capybara::Node::Simple.new(response.body) }

    before do
      test_entry.event.update_attribute(:contact, contact)
      test_entry.update_attribute(:application, application)
    end

    it 'contains application contact' do
      perform_request
      expect(dom).to have_content(contact.to_s)
    end

  end

  describe_action :put, :update, id: true do
    let(:params) { { model_identifier => test_attrs } }

    context '.html', format: :html do
      context 'with valid params', combine: 'uhv' do
        it 'updates answer attributes' do
          as = entry.answers
          expect(as.detect { |a| a.question == event_questions(:top_ov) }.answer).to eq('Halbtax')
          expect(as.detect { |a| a.question == event_questions(:top_vegi) }.answer).to eq('nein')
          expect(as.detect { |a| a.question == event_questions(:top_more) }.answer).to eq('Ne du')
        end
      end
    end
  end

  describe 'GET new' do
    subject { Capybara::Node::Simple.new(response.body) }
    [:event_base, :course].each do |event_sym|
      it "renders title for #{event_sym}" do
        event = send(event_sym)
        get :new, params: { group_id: group.id, event_id: event.id }
        is_expected.to have_content 'Anmeldung als Teilnehmer/-in'
      end
    end
    it 'renders person field when passed for_someone_else param' do
      get :new, params: { group_id: group.id, event_id: course.id, for_someone_else: true }
      person_field = subject.all('form .control-group')[0]
      expect(person_field).to have_content 'Person'
      expect(person_field).to have_css('input', visible: false, count: 2)
      expect(person_field.all('input', visible: false).first[:type]).to eq 'hidden'
    end

    it 'renders alternatives' do
      a = Fabricate(:course, kind_id: course.kind_id)
      a.dates.create!(start_at: course.dates.first.start_at + 2.weeks)
      get :new, params: { group_id: group.id, event_id: course.id }
      is_expected.to have_content a.name
    end
  end

  describe 'GET print' do
    let(:person) { Fabricate(:person_with_address) }
    let(:application) do
      Fabricate(:event_application, priority_1: test_entry.event, participation: test_entry)
    end

    before do
      test_entry.event.update_attribute(:contact, person)
      test_entry.update_attribute(:application, application)
    end

    it 'renders participant and course contact' do
      get :print, params: { group_id: group.id, event_id: test_entry.event.id, id: test_entry.id }, format: :pdf
      expect(response).to be_ok
    end

    it 'redirects users without permission' do
      sign_in(Fabricate(Group::BottomGroup::Member.name.to_s,
                        group: groups(:bottom_group_one_one)).person)
      expect do
        get :print, params: { group_id: group.id, event_id: test_entry.event.id, id: test_entry.id }
      end.to raise_error(CanCan::AccessDenied)
    end
  end

  describe 'participation role label filter' do

    let(:event) { events(:top_event) }
    let(:parti1) { Fabricate(:event_participation, event: event) }
    let(:parti2) { Fabricate(:event_participation, event: event) }
    let(:parti3) { Fabricate(:event_participation, event: event) }

    let(:dom) { Capybara::Node::Simple.new(response.body) }

    before do
      Fabricate(Event::Role::Participant.name.to_sym, participation: parti1, label: 'Foolabel')
      Fabricate(Event::Role::Participant.name.to_sym, participation: parti2, label: 'Foolabel')
      Fabricate(Event::Role::Participant.name.to_sym, participation: parti3, label: 'Just label')
      Event::Participation.page.limit_value.times do
        parti = Fabricate(:event_participation, event: event)
        Fabricate(Event::Role::Participant.name.to_sym, participation: parti)
      end
    end

    it 'filters by event role label' do
      get :index, params: { group_id: event.groups.first.id, event_id: event.id, filter: 'Foolabel' }

      expect(dom).to have_selector('a.dropdown-toggle', text: 'Foolabel')
      expect(dom).to have_selector('.dropdown a', text: 'Foolabel')
      expect(dom).to have_selector('.dropdown a', text: 'Just label')

      expect(dom).to have_selector('a', text: parti1.person.to_s(:list))
      expect(dom).to have_selector('a', text: parti2.person.to_s(:list))
      expect(dom).to have_no_selector('a', text: parti3.person.to_s(:list))
    end

    it 'exports all pages for emails' do
      get :index, params: { group_id: event.groups.first.id, event_id: event.id }, format: 'email'
      expect(dom.text.count('@')).to eq(53)
    end

  end

  context 'preconditions not fullfilled' do
    let(:dom) { Capybara::Node::Simple.new(response.body) }

    before { course.kind.update(minimum_age: 21) }

    it 'displays full warning on detail' do
      Fabricate(:event_role, type: Event::Course::Role::Participant.sti_name, participation: test_entry)
      get :show, params: { group_id: group.id, event_id: course.id, id: test_entry.id }

      expect(dom).to have_content 'Vorbedingungen für Anmeldung sind nicht erfüllt'
    end
  end

end
