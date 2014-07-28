# encoding: utf-8

#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require 'spec_helper'

describe 'event/participations/_list.html.haml' do

  let(:event) { EventDecorator.decorate(Fabricate(:course, groups: [groups(:top_layer)])) }
  let(:participation) { Fabricate(:event_participation, event: event) }
  let(:leader) { Fabricate(Event::Role::Leader.name.to_sym, participation: participation) }

  let(:dom) { render; Capybara::Node::Simple.new(@rendered) }
  let(:dropdowns) { dom.all('.dropdown-toggle') }

  let(:params) do { 'action' => 'index',
                    'controller' => 'event/participations',
                    'group_id' => '1',
                    'event_id' => '36' } end

  before do
    assign(:event, event)
    assign(:group, event.groups.first)
    view.stub(parent: event)
    view.stub(entries: Event::ParticipationDecorator.decorate_collection([participation]))
    view.stub(params: params)
    Fabricate(event.participant_type.name, participation: participation)
  end

  it 'marks participations where required questions are unanswered' do
    login_as(people(:top_leader))

    question = event.questions.create!(question: 'dummy', required: true)
    participation.answers.create!(question: question, answer: '')
    dom.should have_text 'Pflichtangaben fehlen'
  end

  context 'created_at' do

    it 'can be viewed by someone how can show participation details' do
      login_as(people(:top_leader))
      dom.should have_text 'Rollen | Anmeldedatum'
      dom.should have_text "Teilnehmer/-in#{I18n.l(Time.zone.now.to_date)}"
    end

    it 'is not seen by participants' do
      login_as(participation.person)
      dom.should_not have_text 'Rollen | Anmeldedatum'
      dom.should_not have_text "Teilnehmer/-in#{I18n.l(Time.zone.now.to_date)}"
    end

  end

  def login_as(user)
    controller.stub(current_user: user)
    view.stub(current_user: user)
  end
end
