# frozen_string_literal: true

#  Copyright (c) 2012-2020, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.


module MailRelay
  module ManualMailHandling
    # rubocop:disable Rails/Output

    # Use this method in the console to clean up errorenous emails.
    # It should be available as MailRelay::Base.manually_clear_emails
    def manually_clear_emails
      Mail.find_and_delete(count: 10) do |message|
        message.mark_for_delete = should_clear_email?(message)
        puts ""
      end
    end

    private

    def should_clear_email?(message)
      print "Delete message '#{message.subject}' (y/N/i)? "
      case gets.strip.downcase
      when "y"
        true
      when "i"
        inspect_message(message)
      else
        false
      end
    end

    def inspect_message(message)
      puts message
      puts "\n\n"
      should_clear_email?(message)
    end

    # rubocop:enable Rails/Output
  end
end

MailRelay::Base.extend MailRelay::ManualMailHandling
