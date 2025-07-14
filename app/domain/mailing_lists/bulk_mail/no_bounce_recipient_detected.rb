# frozen_string_literal: true

#  Copyright (c) 2025-2025, Schweizer Wanderwege. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module MailingLists::BulkMail
  class NoBounceRecipientDetected < StandardError
    def initialize(imap_mail)
      # rubocop:disable Style/RescueModifier Intentionally ugly, fix the spec-fixtures and specs to allow for more realistic spec
      subject = imap_mail.subject rescue nil
      uid = imap_mail.uid rescue nil
      # rubocop:enable Style/RescueModifier

      msg = "Mail seems to be a bounce, but " \
        "the original recipient could not be detected.\n" \
        "Subject: #{subject}\n" \
        "UID: #{uid}"

      @imap_mail = imap_mail
      super(msg)
    end
  end
end
