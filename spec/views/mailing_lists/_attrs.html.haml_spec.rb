# frozen_string_literal: true

#  Copyright (c) 2023, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

require 'spec_helper'

describe 'mailing_lists/_attrs.html.haml' do

  let(:entry) { mailing_lists(:leaders) }

  before do
    allow(view).to receive(:can?).with(:edit, entry).and_return(false)
    allow(view).to receive(:entry).and_return(entry.decorate)
  end

  subject { Capybara::Node::Simple.new(render) }

  it 'shows email fields when mailing_list#mail_name is set' do
    entry.mail_name = 'test'
    expect(subject).to have_selector 'h2', text: 'Mailing-Liste (E-Mail)'
    expect(subject).to have_selector 'dt', text: 'Mailingliste'
  end

  it 'does not show email fields when mailing_list#mail_name is not set' do
    entry.mail_name = nil
    expect(subject).to have_no_selector 'h2', text: 'Mailing-Liste (E-Mail)'
    expect(subject).to have_no_selector 'dt', text: 'Mailingliste'
  end

  it 'shows mailchimp fields when mail_name is set and user can edit list' do
    entry.mail_name = 'test'
    allow(view).to receive(:can?).with(:edit, entry).and_return(true)
    expect(subject).to have_selector 'h2', text: 'MailChimp'
    expect(subject).to have_selector 'dt', text: 'MailChimp Listen-ID'
  end

  it 'does not show mailchimp fields when mail_name is set but user cannot edit list' do
    entry.mail_name = 'test'
    allow(view).to receive(:can?).with(:edit, entry).and_return(false)
    expect(subject).to have_no_selector 'h2', text: 'MailChimp'
    expect(subject).to have_no_selector 'dt', text: 'MailChimp Listen-ID'
  end

  it 'does not show mailchimp fields when user can edit list but mail_name is not set' do
    entry.mail_name = nil
    allow(view).to receive(:can?).with(:edit, entry).and_return(true)
    expect(subject).to have_no_selector 'h2', text: 'MailChimp'
    expect(subject).to have_no_selector 'dt', text: 'MailChimp Listen-ID'
  end

end
