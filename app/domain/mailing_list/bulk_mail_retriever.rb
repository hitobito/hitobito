# frozen_string_literal: true

# Copyright (c) 2012-2021, Hitobito AG. This file is part of
# hitobito and licensed under the Affero General Public License version 3
# or later. See the COPYING file at the top-level directory or at
# https://github.com/hitobito/hitobito.

module MailingList
  class BulkMailRetriever
    # retrieves mail, checks if it can be assigned to a mailing list and points it to dispatch via FileStore, makes log entry
    # currently in mail_relay/base.rb and mail_relay/lists.rb

    # Number of emails to retrieve in one batch.
    class_attribute :retrieve_count
    #self.retrieve_count = 5
    @retrieve_count = 5
 

    # Retrieve, process and delete all mails from the mail server. 
    def perform       # analog zu relay_current in MailRelay::Base 
      loop do
      # mails, last_exception = relay_batch
      mails = retrieve_batch
      # raise(last_exception) if last_exception.present?
      break if mails.size < @retrieve_count
      end
    end

    def retrieve_batch
      # last_exception = nil
      #imap_connector = ImapConnector.new()
      mails = Mail.find_and_delete(count: @retrieve_count)
      # rescue EOFError => e
      #   logger.warn(e)
      #   [[], nil]
    end
  end
end