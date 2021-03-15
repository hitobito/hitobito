#  frozen_string_literal: true

#  Copyright (c) 2012-2021, Hitobito AG. This file is part of
#  Hitobito AG and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require 'net/imap'

class MailsController < SimpleCrudController
  def initialize
    super

    configure
  end

  def index
    # render mail view
  end

  def configure
    imap = Net::IMAP.new('imap.gmail.com', 993, true)
    imap.login('test.imap.hitobito@gmail.com', 'test.imap')

    imap.select('INBOX')

    mails = imap.fetch(1..10, "ALL")[0].attr

    imap.move(1..10, 'FAILING')

    # imap.search(["ALL"]).each do |message_id|
    #   envelope = imap.fetch(message_id, "ALL")[0]
    #   puts envelope
    # end

  end

  def failed
    @failed ||= Mail.find(mailbox: 'FAIL')
  end

  def spam
    @spam ||= Mail.find(mailbox: 'SPAM')
  end

  def inbox
    @inbox ||= Mail.find(mailbox: 'INBOX')
  end


end
