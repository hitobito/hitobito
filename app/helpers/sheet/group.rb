#  Copyright (c) 2012-2019, Jungwacht Blauring Schweiz. This file is part of
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
        alt: [:group_roles_path, :new_group_csv_imports_path, :group_person_duplicates_path],
        params: { returning: true }

    tab 'activerecord.models.event.other',
        :simple_group_events_path,
        params: { returning: true },
        if: (lambda do |view, group|
          group.event_types.include?(::Event) &&
          view.can?(:index_events, group)
        end)

    tab 'activerecord.models.event/course.other',
        :course_group_events_path,
        params: { returning: true },
        if: (lambda do |view, group|
          group.event_types.include?(::Event::Course) &&
            view.can?(:'index_event/courses', group)
        end)

    tab 'activerecord.models.mailing_list.other',
        :group_mailing_lists_path,
        if: :index_mailing_lists,
        params: { returning: true }

    tab :tab_person_add_request_label,
        :group_person_add_requests_path,
        if: (lambda do |view, group|
          group.layer &&
          view.can?(:index_person_add_requests, group)
        end)

    tab 'activerecord.models.note.other',
        :group_notes_path,
        if: :index_notes

    tab 'groups.tabs.deleted',
        :deleted_subgroups_group_path,
        if: :deleted_subgroups

    tab 'activerecord.models.group_setting.other',
        :group_group_settings_path,
        if: (lambda do |view, group|
          view.can?(:update, group)
        end)

    delegate :group_path, to: :view

    def render_breadcrumbs
      return FormatHelper::EMPTY_STRING unless breadcrumbs?

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
        link_to(g.to_s, group_path(g), data: { disable_with: g.to_s })
      end
    end

    def divider
      content_tag(:li, '>', class: 'divider')
    end

    def breadcrumbs?
      entry.parent_id?
    end

    def belongs_to
      translate(:belongs_to).html_safe + # rubocop:disable Rails/OutputSafety
        FormatHelper::EMPTY_STRING +
        FormatHelper::EMPTY_STRING
    end

  end
end
