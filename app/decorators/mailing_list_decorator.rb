# encoding: utf-8

#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class MailingListDecorator < ApplicationDecorator

  decorates :mailing_list

  def subscribable_info
    html = ''.html_safe
    if !subscribable
      html << translate(:may_not_subscribe).html_safe
    else
      html << translate(:may_subscribe).html_safe
    end
    html << h.tag(:br)
  end

  def subscribers_may_post_info
    html = ''.html_safe
    if !subscribers_may_post
      html << translate(:may_not_post).html_safe
    else
      html << translate(:may_post).html_safe
    end
    html << h.tag(:br)
  end

end
