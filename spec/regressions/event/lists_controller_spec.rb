# encoding: utf-8

#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

# encoding:  utf-8

require 'spec_helper'

describe Event::ListsController, type: :controller do

  render_views

  before { sign_in(people(:top_leader)) }

  let(:dom) { Capybara::Node::Simple.new(response.body) }

  let(:top_group) { groups(:top_group) }
  let(:tomorrow) { 1.day.from_now }
  let(:table) { dom.find('table') }
  let(:description) { 'Impedit rem occaecati quibusdam. Ad voluptatem dolorum hic. Non ad aut repudiandae. ' }
  let(:event) { Fabricate(:event, groups: [top_group], description: description) }

  before  { event.dates.create(start_at: tomorrow) }

  it 'renders title, grouper and selected tab' do
    get :events
    expect(dom).to have_content 'Demnächst stattfindende Anlässe'
    expect(dom).to have_content I18n.l(tomorrow, format: :month_year)
    expect(dom.find('body nav .nav-left-section.active > a').text.strip).to eq 'Anlässe'
  end

  it 'renders event label with link' do
    get :events
    expect(dom.all('table tr a[href]').first[:href]).to eq group_event_path(top_group.id, event.id)
    expect(dom).to have_content 'Eventus'
    expect(dom).to have_content 'TopGroup'
    expect(dom).to have_content I18n.l(tomorrow, format: :time)
    expect(dom).to have_content 'dolorum hi...'
  end

  context 'application' do
    let(:link) { dom.all('table a').last }
    it 'contains apply button for future events' do
      expect(event.application_possible?).to eq true

      get :events

      expect(link.text.strip).to eq 'Anmelden'
      expect(link[:href]).to eq contact_data_group_event_participations_path(event.groups.first,
                                                               event,
                                                               event_role: {
                                                                 type: event.participant_types.first.sti_name})
    end
  end
end
