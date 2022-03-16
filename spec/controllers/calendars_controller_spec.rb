# encoding: utf-8

#  Copyright (c) 2022, Pfadibewegung Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require 'spec_helper'

describe CalendarsController do

  let(:person)   { people(:top_leader) }
  let(:group)    { groups(:top_group) }
  let(:calendar) { Fabricate(:calendar, group: group) }

  before do
    sign_in(person)
    person.roles.destroy_all
  end

  context 'with layer_full or layer_and_below_full permission' do
    before { Fabricate(Group::TopGroup::Leader.name, group: group, person: person) }

    let(:tag1) { Fabricate(:tag) }
    let(:tag2) { Fabricate(:tag) }
    let(:tag3) { Fabricate(:tag) }

    it 'GET#index renders page' do
      get :index, params: { group_id: group.id }
      expect(response).to be_successful
    end

    it 'GET#show renders page' do
      get :show, params: { group_id: group.id, id: calendar.id }
      expect(response).to be_successful
    end

    it 'POST#create creates a new calendar' do
      expect do
        post :create, params: {
            group_id: group.id,
            calendar: {
                name: 'Test calendar',
                description: 'Test description',
                included_calendar_groups_attributes: [{
                    excluded: false,
                    group_id: group.id,
                    # checkbox_tag creates a hidden zero input as well as a checkbox with value 1
                    with_subgroups: [ '0', '1' ],
                    event_type: '',
                    _destroy: false
                }],
                included_calendar_tags_ids: [''],
                excluded_calendar_tags_ids: ['']
            }
        }
      end.to change { Calendar.count }.by 1
      expect(flash[:notice]).to eq 'Kalender-Feed <i>Test calendar</i> wurde erfolgreich erstellt.'
      expect(Calendar.last.included_calendar_groups.count).to eq 1
      expect(Calendar.last.excluded_calendar_groups.count).to eq 0
      expect(Calendar.last.included_calendar_tags.count).to eq 0
      expect(Calendar.last.excluded_calendar_tags.count).to eq 0
    end

    it 'POST#create validates at least one included group' do
      expect do
        post :create, params: {
            group_id: group.id,
            calendar: {
                name: 'Test calendar',
                description: 'Test description',
                included_calendar_groups_attributes: [],
                included_calendar_tags_ids: [''],
                excluded_calendar_tags_ids: ['']
            }
        }
      end.to change { Calendar.count }.by 0
      calendar = assigns(:calendar)
      expect(calendar).not_to be_valid
      expect(calendar.errors.messages[:included_calendar_groups]).to include('muss ausgefüllt werden')
    end

    it 'POST#create creates a new calendar with tags and excluded groups' do
      expect do
        post :create, params: {
            group_id: group.id,
            calendar: {
                name: 'Test calendar',
                description: 'Test description',
                included_calendar_groups_attributes: [{
                    excluded: false,
                    group_id: group.id,
                    # checkbox_tag creates a hidden zero input as well as a checkbox with value 1
                    with_subgroups: [ '0', '1' ],
                    event_type: '',
                    _destroy: false
                }],
                excluded_calendar_groups_attributes: [{
                    excluded: true,
                    group_id: group.id,
                    with_subgroups: [ '0' ],
                    event_type: 'Event',
                    _destroy: false
                }, {
                    excluded: true,
                    group_id: group.id,
                    with_subgroups: [ '0', '1' ],
                    event_type: 'Event::Course',
                    _destroy: false
                }],
                included_calendar_tags_ids: ['', tag1.id.to_s],
                excluded_calendar_tags_ids: ['', tag2.id.to_s, tag3.id.to_s]
            }
        }
      end.to change { Calendar.count }.by 1
      expect(flash[:notice]).to eq 'Kalender-Feed <i>Test calendar</i> wurde erfolgreich erstellt.'
      expect(Calendar.last.included_calendar_groups.count).to eq 1
      expect(Calendar.last.excluded_calendar_groups.count).to eq 2
      expect(Calendar.last.included_calendar_tags.count).to eq 1
      expect(Calendar.last.excluded_calendar_tags.count).to eq 2
    end
  end

  context 'without layer_full or layer_and_below_full permission' do
    before { Fabricate(Group::TopGroup::Secretary.name, group: group, person: person) }

    it 'GET#index denies access' do
      expect do
        get :index, params: { group_id: group.id }
      end.to raise_error(CanCan::AccessDenied)
    end

    it 'GET#show denies access' do
      expect do
        get :show, params: { group_id: group.id, id: calendar.id }
      end.to raise_error(CanCan::AccessDenied)
    end

    it 'POST#create denies access' do
      expect do
        post :create, params: {
            group_id: group.id,
            calendar: {
                name: 'Test calendar',
                description: 'Test description',
                included_calendar_groups_attributes: [{
                                                          excluded: false,
                                                          group_id: group.id,
                                                          # checkbox_tag creates a hidden zero input as well as a checkbox with value 1
                                                          with_subgroups: [ '0', '1' ],
                                                          event_type: '',
                                                          _destroy: false
                                                      }],
                included_calendar_tags_ids: [''],
                excluded_calendar_tags_ids: ['']
            }
        }
      end.to raise_error(CanCan::AccessDenied)
    end
  end

end
