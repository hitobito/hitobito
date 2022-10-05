# frozen_string_literal: true

#  Copyright (c) 2022, Pfadibewegung Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require 'spec_helper'

describe MailingLists::ImapMailsHelper do

  FakeMail = Struct.new(:subject, keyword_init: true)

  it 'truncates the subject' do
    mail = FakeMail.new(subject: 'A very long subject that exceeds some internal threshold')

    expect(imap_mail_subject(mail)).to eq 'A very long subject that exceeds some int...'
  end

  it 'replaces empty subjects' do
    mail = FakeMail.new(subject: nil)

    expect(imap_mail_subject(mail)).to eq 'unbekannt'
  end

  it 'leaves most subjects as is' do
    mail = FakeMail.new(subject: 'Normal Subject')

    expect(imap_mail_subject(mail)).to eq 'Normal Subject'
  end

  it 'sanitizes the subject' do
    mail = FakeMail.new(subject: '<script>console.log("Foo")</script>')

    expect(imap_mail_subject(mail)).to eq 'console.log("Foo")'
  end
end
