#  frozen_string_literal: true

#  Copyright (c) 2012-2022, Hitobito AG. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module Mails::ImapMailsHelper
  def imap_mail_table(template, *attrs)
    options = attrs.extract_options!
    template.add_css_class(options, "table table-striped table-hover")

    table(mails, options.merge(data: {checkable: true})) do |t|
      yield t if block_given?
    end
  end

  def imap_mail_mailbox?(name)
    mailbox == name
  end

  def imap_mail_move_button(to)
    return if to == mailbox

    action_button(t(("mailing_lists.imap_mails.move_to." + to.to_s).to_sym),
      imap_mails_move_path(dst_mailbox: to),
      :"arrow-right",
      data: {checkable: true, method: :patch})
  end

  def imap_mail_subject(mail)
    subject = mail.subject

    return t("global.unknown") if subject.nil?

    if subject.length > 43
      subject = subject[0..40] + "..."
    end
    sanitize(subject)
  end

  def imap_mail_body(mail)
    body = mail.body
    if body.length > 43
      body = body[0..40] + "..."
    end
    sanitize(body)
  end

  def imap_mail_state(mail)
    state = mail_log_state(mail)
    sanitize(state)
  end

  def imap_mail_date(mail)
    date = mail.date
    if date.today?
      I18n.l(date, format: :time)
    else
      I18n.l(date.to_date) + " " + I18n.l(date, format: :time)
    end
  end

  private

  def mail_log_state(mail)
    mail_log_entry = MailLog.find_by(mail_hash: mail.hash)
    return "state_unavailable" if mail_log_entry.nil?

    mail_log_entry.status
  end
end
