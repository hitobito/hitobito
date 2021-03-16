# encoding: utf-8

#  Copyright (c) 2021, Hitobito AG. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require 'net/imap'

class CatchAllMail

  include ActiveModel::Model
  include ActiveModel::Conversion
  extend ActiveModel::Naming


  attr_accessor :uid, :mailbox, :subject, :date, :sender, :body

  def initialize(imap_fetch_data=nil, mailbox='')

    @mailbox = mailbox

    if imap_fetch_data.nil?
      @uid = 0
      @subject = ''
      @date = ''
      @sender = ''
      @body = ''
    else
      @uid = imap_fetch_data.attr['UID']

      env = imap_fetch_data.attr['ENVELOPE']
      @subject = env.subject
      @date = env.date
      @sender = env.sender[0].mailbox + '@' + env.sender[0].host

      body_with_encoding_error = imap_fetch_data.attr['BODY[TEXT]']
      @body = body_with_encoding_error.to_s.force_encoding('UTF-8')
    end

  end

  def persisted?
    false
  end


end

