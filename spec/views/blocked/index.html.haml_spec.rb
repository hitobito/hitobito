# encoding: utf-8

#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require 'spec_helper'
describe 'blocked/index.html.haml' do

  let(:person) { people(:bottom_member) }
  let(:current_user) { person }
  let(:warn_after) { 18.months }
  let(:block_after) { 1.month }

  subject do
    allow(controller).to receive_messages(current_user: current_user)
    allow(view).to receive_messages(current_user: current_user)
    allow(Person::BlockService).to receive(:warn_after).and_return(warn_after)
    allow(Person::BlockService).to receive(:block_after).and_return(block_after)
    render
    Capybara::Node::Simple.new(@rendered)
  end

  it 'shows the explanation' do
    is_expected.to have_content I18n.t('blocked.index.explanation')
  end
end
