# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito

require 'spec_helper'

describe :hitobito_log_entries do

  before do
    sign_in
    visit hitobito_log_entries_path
  end

  def tabs
    expect(page).to have_selector('.sheet.current .content-header .nav-sub li a')
    all('.sheet.current .content-header .nav-sub li a').map { |a| a.text }
  end

  it 'has expected tabs' do
    expect(tabs).to match_array %w(Alle Webhook Ebics Mail)
  end

  it 'tabs filter by category' do
    expect(page).to have_selector('.hitobito-log tbody tr', count: 6)

    visit hitobito_log_entries_path(category: 'ebics')
    expect(page).to have_selector('.hitobito-log tbody tr', count: 1)

    visit hitobito_log_entries_path(category: 'webhook')
    expect(page).to have_selector('.hitobito-log tbody tr', count: 4)
  end

  it 'current tab is active' do
    visit hitobito_log_entries_path(category: 'ebics')
    expect(page.find('.sheet.current .content-header .nav-sub li.active a').text).to eq('Ebics')
  end

end
