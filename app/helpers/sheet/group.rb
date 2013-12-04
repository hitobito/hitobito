# encoding: utf-8

#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module Sheet
  class Group < Base
    self.has_tabs = true

    delegate :group_path, to: :view

    def render_breadcrumbs
      return ''.html_safe unless breadcrumbs?

      content_tag(:div, class: 'breadcrumb') do
        content_tag(:ul) do
          crumbs = breadcrumbs.reverse.collect do |crumb|
            content_tag(:li, crumb)
          end

          content_tag(:li, 'geh&ouml;rt zu&nbsp;'.html_safe) +
          StandardHelper::EMPTY_STRING +
          safe_join(crumbs, divider)
        end
      end
    end

    def title
      entry.deleted? ? "#{super} (gelöscht)" : super
    end

    private

    def link_url
      group_path(entry.id)
    end

    def breadcrumbs
      entry.parent.hierarchy.collect do |g|
        link_to(g.to_s, group_path(g))
      end
    end

    def divider
      content_tag(:li, '>', class: 'divider')
    end

    def breadcrumbs?
      entry.parent_id?
    end

  end
end
