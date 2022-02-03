# encoding: utf-8

#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module GroupsHelper

  def tab_person_add_request_label(group)
    label = t('activerecord.models.person/add_request.other')
    count = Person::AddRequest.for_layer(group).count
    label << " (#{count})" if count > 0
    label.html_safe
  end

  def format_self_registration_link(group)
    url = group_self_registration_url(group)
    link_to(url, url)
  end

  def maybe_value(value)
    value || t('global.unknown')
  end

  def distribution_bar_width(count, count_max)
    normalized = count / count_max
    "#{normalized * 100}%"
  end
end
