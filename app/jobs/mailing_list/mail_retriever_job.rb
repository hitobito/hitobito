# frozen_string_literal: true

# Copyright (c) 2012-2021, Hitobito AG. This file is part of
# hitobito and licensed under the Affero General Public License version 3
# or later. See the COPYING file at the top-level directory or at
# https://github.com/hitobito/hitobito.


module MailingList
    class MailRetrieverJob < RecurringJob
  
      run_every Settings.email.retriever.interval.minutes
      
      def perform_internal
        # only run if a retriever address is defined
        if Settings.email.retriever.config.address
          retriever.perform
        end
      end
          
      private
  
      def retriever
        MailingList::BulkMailRetriever.new
      end
    end
  end