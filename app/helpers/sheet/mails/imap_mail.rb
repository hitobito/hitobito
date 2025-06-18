# frozen_string_literal: true

module Sheet
  module Mails
    class ImapMail < Sheet::Admin
      def title = I18n.t("navigation.imap_mails")

      tab "mailing_lists.imap_mails.manage",
        :imap_mails_path, params: {mailbox: "inbox"}, no_alt: true

      tab "mailing_lists.bounces.manage",
        :bounces_path, params: {locale: I18n.locale}
    end
  end
end
