# encoding: utf-8

#  Copyright (c) 2019, hitobito AG. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module TagListsHelper

  def available_tags_checkboxes(tags)
    safe_join(tags.map do |tag, count|
      content_tag(:div, class: 'control-group  available-tag') do
        tag_checkbox(tag, count)
      end
    end, '')
  end

  private

  def tag_checkbox(tag, count)
    label_tag(nil, class: 'checkbox ') do
      out = check_box_tag("tags[]", tag.name, false)
      out << tag
      out << content_tag(:div, class: 'role-count') do
        count.to_s
      end
      out.html_safe
    end
  end
end
