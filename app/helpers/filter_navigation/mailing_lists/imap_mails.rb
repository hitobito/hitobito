#  frozen_string_literal: true

#  Copyright (c) 2012-2021, Hitobito AG. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module FilterNavigation::MailingLists
  class ImapMails < FilterNavigation::Base

    def initialize(template)
      super(template)
      init_items
    end

    def active_label
      label_for_filter(template.mailbox)
    end

    private

    def init_items
      filter_item('inbox')
      filter_item('spam')
      filter_item('failed')
    end

    def filter_item(name)
      item(label_for_filter(name), filter_path(name))
    end

    def counts
      template.counts
    end

    def label_for_filter(filter)
      count_str = counts[filter.to_sym].to_s
      template.t("mailing_lists.imap_mails.mailboxes.#{filter.downcase}") + " (#{count_str})"
    end

    def filter_path(name)
      template.url_for(mailbox: name.downcase, only_path: true)
    end

  end
end
