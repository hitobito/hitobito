# encoding: utf-8

#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require 'spec_helper'

describe Event::ListsController do
  render_views
  before { sign_in(person) }
  let(:person) { people(:bottom_member) }

  it 'populates events in group_hierarchy, order by start_at' do
    a = create_event(:bottom_layer_one)
    b = create_event(:top_layer, start_at: 1.year.ago)

    get :events

    expect(assigns(:grouped_events).values).to eq [[b], [a]]
  end

  it 'does not include courses' do
    create_event(:top_layer, type: :course)

    get :events

    expect(assigns(:grouped_events)).to be_empty
  end

  it 'groups by month' do
    create_event(:top_layer, start_at: Time.zone.parse('2012-10-30'))
    create_event(:top_layer, start_at: Time.zone.parse('2012-11-1'))

    get :events

    expect(assigns(:grouped_events).keys).to eq(['Oktober 2012', 'November 2012'])
  end

  def create_event(group, hash = {})
    hash = { start_at: 4.days.ago, finish_at: 1.day.from_now, type: :event }.merge(hash)
    event = Fabricate(hash[:type], groups: [groups(group)])
    event.dates.create(start_at: hash[:start_at], finish_at: hash[:finish_at])
    event
  end

end
