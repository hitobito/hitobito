# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require 'spec_helper'

describe 'Mailing list subscribers' do
  let(:list) { mailing_lists(:leaders) }

  it 'can create new invoice list' do
    sign_in
    visit group_mailing_list_subscriptions_path(group_id: list.group_id, mailing_list_id: list.id)
    click_on 'Rechnung erstellen'
    expect(page).to have_css('h1', text: 'Sammelrechnungen')
  end
end
