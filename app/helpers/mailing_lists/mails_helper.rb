#  Copyright (c) 2012-2021, Hitobito AG. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module MailingLists::MailsHelper

  def mail_table(template, *attrs)
    options = attrs.extract_options!
    template.add_css_class(options, 'table table-striped table-hover')

    table(mails, options.merge(data: { checkable: true })) do |t|
      yield t if block_given?
    end
  end

  def mail_mailbox_failed?
    mailbox == 'failed'
  end

  def mail_move_button(to)
    if mailbox == to.to_s
      return
    end

    action_button(t(('mails.move_to.' + to.to_s).to_sym),
                  imap_mails_move_path(from: mailbox, to: to),
                  :'arrow-right',
                  data: { checkable: true, method: :patch })
  end

end
