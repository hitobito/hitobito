# encoding: utf-8

#  Copyright (c) 2012-2020, CVP Schweiz. This file is part of
#  hitobito_cvp and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_cvp.

module MailLogHelper

  def format_mail_log_status(mail_log)
    type = case mail_log.status
           when /retreived|bulk_delivering/ then "info"
           when /sender_rejected|unkown_recipient/ then "important"
           when /completed/ then "success"
           end
    badge(mail_log_status_label(mail_log), type)
  end

  def mail_log_status_label(mail_log)
    i18n_prefix = "activerecord.attributes.mail_log"
    t("#{i18n_prefix}.statuses.#{mail_log.status}")
  end

end
