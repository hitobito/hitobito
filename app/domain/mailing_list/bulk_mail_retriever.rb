# encoding: utf-8

#  Copyright (c) 2012-2018, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module MailingList
    class BulkMailRetriever
        # retrieves mail, checks if it can be assigned to a mailing list and points it to dispatch via FileStore, makes log entry
        # currently in mail_relay/base.rb and mail_relay/lists.rb

        # Retrieve, process and delete all mails from the mail server. 
        def perform       # analog zu relay_current in MailRelay::Base 
            loop do
              mails, last_exception = relay_batch
              raise(last_exception) if last_exception.present?
              break if mails.size < retrieve_count
            end
        end

        def relay_batch
            last_exception = nil
    
            mails = Mail.find_and_delete(count: retrieve_count) do |message|
              proccessed_error = process(message)
              last_exception = proccessed_error if proccessed_error
            end
    
            [mails || [], last_exception]
          rescue EOFError => e
            logger.warn(e)
            [[], nil]
        end

        

    end
end