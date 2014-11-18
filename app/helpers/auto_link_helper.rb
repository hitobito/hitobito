# encoding: utf-8

#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module AutoLinkHelper

  def auto_link(str, options = {})
    if email?(str)
      mail_to(str)
    elsif url_with_protocol?(str)
      link_to_blank(str, str, options)
    elsif url_without_protocol?(str)
      url = 'http://' + str
      link_to_blank(str, url, options)
    else
      str
    end
  end

  def email?(str)
    /\A([\w\.\-\+]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})\z/i.match(str)
  end

  def url?(str)
    url_with_protocol?(str) || url_without_protocol?(str)
  end

  def url_with_protocol?(str)
    # includes no white-spaces AND includes proto://
    /(?=^\S*$)(?=([a-z]*:\/\/.*$)).*/.match(str)
  end

  def url_without_protocol?(str)
    # includes no white-spaces AND includes www.*
    /(?=^\S*$)(?=(^www\..+$)).*/.match(str)
  end

  def link_to_blank(label, url, options = {})
    options[:target] ||= '_blank'
    link_to(label, url, options)
  end

end
