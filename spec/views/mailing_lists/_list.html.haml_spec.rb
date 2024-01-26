# frozen_string_literal: true

#  Copyright (c) 2023, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

require 'spec_helper'

describe 'mailing_lists/_list.html.haml' do

  let(:entry) { mailing_lists(:leaders) }

  before do
    allow(view).to receive(:can?)
    allow(view).to receive(:entries).and_return([entry])
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
