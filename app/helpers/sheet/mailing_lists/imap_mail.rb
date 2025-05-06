# frozen_string_literal: true

module Sheet
  module MailingLists
    class ImapMail < Sheet::Admin
      def title = I18n.t("mailing_lists.imap_mails.manage")

      tab "mailing_lists.imap_mails.manage", :imap_mails_path, params: {mailbox: 'inbox'}
      tab "mailing_lists.bounces.manage",    :bounces_path, params: {locale: I18n.locale}
    end
  end
end
