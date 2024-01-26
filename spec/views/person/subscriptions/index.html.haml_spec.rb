# frozen_string_literal: true

#  Copyright (c) 2023, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

require 'spec_helper'

describe 'person/subscriptions/index.html.haml' do

  let(:group) { groups(:top_layer) }
  let(:person) { people(:top_leader) }
  let(:entry) { mailing_lists(:leaders) }

  before do
    allow(view).to receive(:can?)
    allow(view).to receive(:subscribed).and_return([])
    allow(view).to receive(:subscribable).and_return({ group => [entry] })
    allow(view).to receive(:group_person_subscriptions_path).and_return(group_person_subscriptions_path(group, person, entry))
  end

  subject { Capybara::Node::Simple.new(render) }

  it 'renders name as link if current_user can read' do
    allow(view).to receive(:can?).with(:show, entry).and_return(true)
    expect(subject).to have_selector 'td strong a', text: entry.name
  end

  it 'renders name as text if current_user cannot read' do
    allow(view).to receive(:can?).with(:show, entry).and_return(false)
    expect(subject).to have_selector 'td strong', text: entry.name
    expect(subject).to have_no_selector 'td strong a', text: entry.name
  end

end
