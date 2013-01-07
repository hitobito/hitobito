# encoding: utf-8
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
