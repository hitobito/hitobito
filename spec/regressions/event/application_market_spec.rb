# encoding: utf-8

#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require 'spec_helper'

describe Event::ApplicationMarketController, type: :controller do

  render_views

  let(:group)  { course.groups.first }
  let(:course) { events(:top_course) }

  before do
    Fabricate(:event_participation, event: course, application: Fabricate(:event_application, priority_1: course))
    Fabricate(:event_participation, application: Fabricate(:event_application, priority_2: course))
    Fabricate(:event_participation, application: Fabricate(:event_application, priority_3: course))

    Fabricate(course.participant_types.first.name.to_sym,
              participation: Fabricate(:event_participation,
                                       event: course,
                                       active: true,
                                       application: Fabricate(:event_application)))
    Fabricate(course.participant_types.first.name.to_sym,
              participation: Fabricate(:event_participation,
                                       event: course,
                                       active: true,
                                       application: Fabricate(:event_application)))

    sign_in(people(:top_leader))
  end


  describe 'GET index' do

    before { get :index, event_id: course.id, group_id: group.id }

    let(:dom) { Capybara::Node::Simple.new(response.body) }

    it { is_expected.to render_template('index') }

    it 'has participants' do
      expect(assigns(:participants).size).to eq(2)
    end

    it 'has applications' do
      expect(assigns(:applications).size).to eq(1)
    end

    it 'has event' do
      expect(assigns(:event)).to eq(course)
    end

    it 'has add button' do
      button = dom.find('.btn-group a')
      expect(button.text).to eq ' Teilnehmer/-in hinzufügen'
      expect(button).to have_css('i.icon-plus')
      expect(button[:href]).to eq new_group_event_participation_path(group,
                                                                 course,
                                                                 for_someone_else: true,
                                                                 event_role: {
                                                                   type: course.class.participant_types.first.sti_name })
    end
  end


end
