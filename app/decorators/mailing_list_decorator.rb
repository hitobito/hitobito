# encoding: utf-8

#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class MailingListDecorator < ApplicationDecorator

  decorates :mailing_list

  def subscribable_info
    html = ''.html_safe
    html << 'Abonnenten dürfen sich'
    if !subscribable
      html << content_tag(:strong, ' nicht')
    end
    html << ' selbst an/abmelden'
    html << h.tag(:br)
  end

  def subscribers_may_post_info
    html = ''.html_safe
    html << 'Abonnenten dürfen'
    if !subscribers_may_post
      html << content_tag(:strong, ' nicht')
    end
    html << ' auf die Mailingliste schreiben'
    html << h.tag(:br)
  end

end
