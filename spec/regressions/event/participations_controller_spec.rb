# encoding: utf-8

#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

# encoding:  utf-8

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
        { answer: 'Ne du',   question_id: event_questions(:top_more).id },
      ],
      application_attributes: { priority_2_id: nil }
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
    let(:application) { Fabricate(:event_application, priority_1: test_entry.event, participation: test_entry) }

    let(:dom) { Capybara::Node::Simple.new(response.body) }

    before do
      test_entry.event.update_attribute(:contact, contact)
      test_entry.update_attribute(:application, application)
    end

    it 'contains application contact' do
      perform_request
      dom.should have_content(contact.to_s)
    end

  end

  describe_action :put, :update, id: true do
    let(:params) { { model_identifier => test_attrs } }

    context '.html', format: :html do
      context 'with valid params', combine: 'uhv' do
        it 'updates answer attributes' do
          as = entry.answers
          as.detect { |a| a.question == event_questions(:top_ov) }.answer.should == 'Halbtax'
          as.detect { |a| a.question == event_questions(:top_vegi) }.answer.should == 'nein'
          as.detect { |a| a.question == event_questions(:top_more) }.answer.should == 'Ne du'
        end
      end
    end
  end

  describe 'POST create' do
    [:event_base, :course].each do |event_sym|
      it "prompts to change contact data for #{event_sym}" do
        event = send(event_sym)
        post :create, group_id: group.id, event_id: event.id, event_participation: test_entry_attrs
        flash[:notice].should =~ /Bitte überprüfe die Kontaktdaten/
        should redirect_to group_event_participation_path(group, event, assigns(:participation))
      end
    end
  end

  describe 'GET new' do
    subject { Capybara::Node::Simple.new(response.body) }
    [:event_base, :course].each do |event_sym|
      it "renders title for #{event_sym}" do
        event = send(event_sym)
        get :new, group_id: group.id, event_id: event.id
        should have_content "Anmeldung für #{event.name}"
      end
    end
    it 'renders person field when passed for_someone_else param' do
      get :new, group_id: group.id, event_id: course.id, for_someone_else: true
      person_field = subject.all('form .control-group')[0]
      person_field.should have_content 'Person'
      person_field.should have_css('input', count: 2)
      person_field.all('input').first[:type].should eq 'hidden'
    end

    it 'renders alternatives' do
      a = Fabricate(:course, kind_id: course.kind_id)
      a.dates.create!(start_at: course.dates.first.start_at + 2.weeks)
      get :new, group_id: group.id, event_id: course.id
      should have_content a.name
    end
  end

  describe_action :delete, :destroy, format: :html, id: true do
    it 'redirects to application market' do
      should redirect_to group_event_application_market_index_path(group, course)
    end

    it 'has flash noting the application' do
      flash[:notice].should =~ /Anmeldung/
    end
  end

  describe 'GET print' do
    subject { response.body }
    let(:person) { Fabricate(:person_with_address) }
    let(:application) { Fabricate(:event_application, priority_1: test_entry.event, participation: test_entry) }

    let(:dom) { Capybara::Node::Simple.new(response.body) }

    before do
      test_entry.event.update_attribute(:contact, person)
      test_entry.update_attribute(:application, application)
    end

    it 'renders participant and course contact' do
      get :print, group_id: group.id, event_id: test_entry.event.id, id: test_entry.id, format: :pdf
      response.should be_ok
    end

    it 'redirects users without permission' do
      sign_in(Fabricate(Group::BottomGroup::Member.name.to_s, group: groups(:bottom_group_one_one)).person)
      expect do
        get :print, group_id: group.id, event_id: test_entry.event.id, id: test_entry.id
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
    end

    it 'filters by event role label' do
      get :index, group_id: event.groups.first.id, event_id: event.id, filter: 'Foolabel'

      dom.should have_selector('a.dropdown-toggle', text: 'Foolabel')
      dom.should have_selector('.dropdown a', text: 'Foolabel')
      dom.should have_selector('.dropdown a', text: 'Just label')

      dom.should have_selector('a', text: parti1.person.to_s(:list))
      dom.should have_selector('a', text: parti2.person.to_s(:list))
      dom.should have_no_selector('a', text: parti3.person.to_s(:list))
    end

  end

end
