# frozen_string_literal: true

# Copyright (c) 2012-2021, Hitobito AG. This file is part of
# hitobito and licensed under the Affero General Public License version 3
# or later. See the COPYING file at the top-level directory or at
# https://github.com/hitobito/hitobito.


module MailingList
    class BulkMailRetriever

      attr_accessor :retrieve_count, :imap_connector
      @retrieve_count = 5  
      @imap_connector = IMAP::Connector.new
  
      def perform
        # retrieve mail
        mails = []
        mails << imap_connector.fetch_mails(inbox)
      end

      def reject_not_existing
        # mail abozugehörig?
      end 
      
      private

      # MAILBOX = { inbox: 'INBOX' }.with_indifferent_access.freeze

    end
  end
