# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.
#
module TabsHelper

  def tab_header(label, id, default_active: false)
    tab = params[:active_tab]
    classes = %w(nav-link)
    classes += %w(active) if default_active && tab.blank? || tab == id.to_s
    link_to(label, "##{id}", data: { bs_toggle: 'tab' }, class: classes)
  end

  def tab_content(id, default_active: false, &block)
    tab = params[:active_tab]
    classes = %w(tab-pane)
    classes += %w(active) if default_active && tab.blank? || tab == id.to_s
    content_tag(:div, capture(&block), id: id, class: classes)
  end
end
