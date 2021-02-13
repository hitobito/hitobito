# encoding: utf-8

#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class MailingListDecorator < ApplicationDecorator
  decorates :mailing_list

  def mail_address_link
    h.mail_to(mail_address)
  end

  def subscribable_info
    html = "".html_safe
    html << if !subscribable
      translate(:may_not_subscribe).html_safe
            else
              translate(:may_subscribe).html_safe
            end
    html << h.tag(:br)
  end

  def subscribers_may_post_info
    html = "".html_safe
    html << if !subscribers_may_post
      translate(:subscribers_may_not_post).html_safe
            else
              translate(:subscribers_may_post).html_safe
            end
    html << h.tag(:br)
  end

  def anyone_may_post_info
    html = "".html_safe
    html << if !anyone_may_post
      translate(:anyone_may_not_post).html_safe
            else
              translate(:anyone_may_post).html_safe
            end
    html << h.tag(:br)
  end

  def delivery_report_info
    html = "".html_safe
    html << if !delivery_report
      translate(:no_delivery_report).html_safe
            else
              translate(:delivery_report).html_safe
            end
    html << h.tag(:br)
  end
end
