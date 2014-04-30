# encoding: utf-8

#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module Sheet
  class Group < Base
    tab 'global.tabs.info',
        :group_path,
        no_alt: true

    tab 'activerecord.models.person.other',
        :group_people_path,
        if: :index_people,
        alt: [:group_roles_path, :new_group_csv_imports_path],
        params: { returning: true }

    ::Event.all_types.each do |type|
      tab "activerecord.models.#{type.model_name.i18n_key}.other",
          "#{type.type_name}_group_events_path",
          params: { returning: true },
          if: lambda { |view, group|
            group.event_types.include?(type) && view.can?(:index_events, group)
          }
    end

    tab 'activerecord.models.mailing_list.other',
        :group_mailing_lists_path,
        if: :index_mailing_lists,
        params: { returning: true }

    tab 'groups.tabs.deleted',
        :deleted_subgroups_group_path,
        if: :deleted_subgroups


    delegate :group_path, to: :view

    def render_breadcrumbs
      return ''.html_safe unless breadcrumbs?

      content_tag(:div, class: 'breadcrumb') do
        content_tag(:ul) do
          crumbs = breadcrumbs.reverse.collect do |crumb|
            content_tag(:li, crumb)
          end

          content_tag(:li, belongs_to) + safe_join(crumbs, divider)
        end
      end
    end

    def title
      entry.deleted? ? "#{super} #{translate(:deleted)}" : super
    end

    def left_nav?
      true
    end

    def render_left_nav
      NavLeft.new(self).render
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

    def belongs_to
      translate(:belongs_to).html_safe +
        StandardHelper::EMPTY_STRING +
        StandardHelper::EMPTY_STRING
    end

  end
end
