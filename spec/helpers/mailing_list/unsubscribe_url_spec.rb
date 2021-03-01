# frozen_string_literal: true

#  Copyright (c) 2021, Hitobito AG. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require 'spec_helper'

describe MailingList::UnsubscribeUrl do
  let(:mailing_list) { mailing_lists(:leaders) }
  let(:link) { MailingList::UnsubscribeUrl.unsubscribe_link(mailing_list) }
  let(:link_with_html) { MailingList::UnsubscribeUrl.unsubscribe_link(mailing_list, html: true) }

  context 'protocol' do
    with_ssl = 'https://'
    without_ssl = 'http://'

    it 'should include https' do
      expect(Rails.application.config).to receive(:force_ssl).and_return(true)
      expect(link).to include(with_ssl)
    end

    it 'should not include https' do
      expect(link).to include(without_ssl)
    end
  end

  context 'link' do
    anchor_tag = '<a href='

    it 'should be clickable' do
      expect(link_with_html).to include(anchor_tag)
    end

    it 'should be text' do
      expect(link).not_to include(anchor_tag)
    end
  end

  context 'host' do
    it 'adds host by environment variable fallback if env nonexistent' do
      host = ENV.fetch('RAILS_HOST_NAME', 'localhost:3000')
      expect(link).to include(host)
    end

    it 'adds host by environment variable' do
      ENV['RAILS_HOST_NAME'] = '127.0.0.1:3000'
      host = ENV.fetch('RAILS_HOST_NAME', 'localhost:3000')
      expect(link).to include(host)
      ENV.delete('RAILS_HOST_NAME')
    end
  end

  context 'text' do
    unsubscribe_text = 'Abmelden / Unsubscribe: http://localhost:3000/groups/834963567/mailing_lists/55339926'

    it 'contains unsubscribe text' do
      expect(link).to eq(unsubscribe_text)
    end
  end
end
