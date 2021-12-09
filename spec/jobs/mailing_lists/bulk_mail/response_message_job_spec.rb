# frozen_string_literal: true

# Copyright (c) 2012-2021, Hitobito AG. This file is part of
# hitobito and licensed under the Affero General Public License version 3
# or later. See the COPYING file at the top-level directory or at
# https://github.com/hitobito/hitobito.


require 'spec_helper'

describe MailingLists::BulkMail::ResponseMessageJob do
  include MailingLists::ImapMailsHelper

  let(:mail)       { built_imap_mail(plain_body: true) }
  let(:letter)     { messages(:letter) }
  let(:top_leader) { people(:top_leader) }
  let(:bottom_member) { people(:bottom_member) }

  context 'send unallowed message to sender' do
    subject { described_class.new(mail, :sender_rejected) }

    it 'delivers' do
      Settings.email.retriever.config = Config::Options.new(address: 'localhost')
      binding.pry
      subject.perform
      expect(subject.delayed_jobs).to be_exists
    end
  end
end
