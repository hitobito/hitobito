#  Copyright (c) 2012-2021, Hitobito AG. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module MailingLists::ImapMailsHelper

  def imap_mail_table(template, *attrs)
    options = attrs.extract_options!
    template.add_css_class(options, 'table table-striped table-hover')

    table(mails, options.merge(data: { checkable: true })) do |t|
      yield t if block_given?
    end
  end

  def imap_mail_mailbox?(name)
    mailbox == name
  end

  def imap_mail_move_button(to)
    if mailbox == to.to_s
      return
    end

    action_button(t(('mails.move_to.' + to.to_s).to_sym),
                  imap_mails_move_path(mail_dst: to),
                  :'arrow-right',
                  data: { checkable: true, method: :patch })
  end

  def imap_mail_subject(mail)
    subject = mail.subject
    if subject.length > 43
      subject = subject[0..40] + '...'
    end
    sanitize(subject)
  end

  def imap_mail_body(mail)
    body = mail.body
    if body.length > 43
      body = body[0..40] + '...'
    end
    sanitize(body)
  end

  def imap_mail_date(mail)
    date = mail.date
    if date.today?
      I18n.l(date, format: :time)
    else
      I18n.l(date.to_date) + ' ' + I18n.l(date, format: :time)
    end
  end
end
