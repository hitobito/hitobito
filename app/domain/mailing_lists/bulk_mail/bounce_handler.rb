# frozen_string_literal: true

#  Copyright (c) 2022, Hitobito AG. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module MailingLists::BulkMail
  class BounceHandler

    def initialize(mail, mailing_list)
      @mail = mail
      @mailing_list = mailing_list
    end

    def bounce_mail?
      bounce_return_path? &&
        @mail.bounce_hitobito_message_uid.present?
    end

    def process
    end

    private

    def bounce_return_path?
      return_path.eql?('') ||
        return_path.include?('MAILER-DAEMON')
    end

    def return_path
      @mail.return_path
    end

  end
end
