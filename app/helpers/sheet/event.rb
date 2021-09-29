# encoding: utf-8

#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module Sheet
  class Event < Base
    self.parent_sheet = Sheet::Group

    class << self

      private

      def can_view_qualifications?(view, event)
        view.can?(:qualify, event) || view.can?(:qualifications_read, event)
      end

    end

    tab 'global.tabs.info',
        :group_event_path,
        if: :show,
        no_alt: true

    tab 'events.tabs.participants',
        :group_event_participations_path,
        if: (lambda do |view, _group, event|
          event.participant_types.present? && view.can?(:index_participations, event)
        end),
        alt: [:group_event_roles_path],
        params: { returning: true }

    tab 'activerecord.models.event/application.other',
        :group_event_application_market_index_path,
        if: (lambda do |view, _group, event|
          event.supports_applications && view.can?(:application_market, event)
        end)

    tab 'activerecord.models.qualification.other',
        :group_event_qualifications_path,
        if: (lambda do |view, _group, event|
          event.course_kind? && event.qualifying? &&
            can_view_qualifications?(view, event)
        end)

    tab 'activerecord.models.event/invitation.other',
        :group_event_invitations_path,
        if: (lambda do |view, _group, event|
          view.can?(:index_invitations, event)
        end)

    def link_url
      view.group_event_path(parent_sheet.entry.id, entry.id)
    end

    def current_parent_nav_path
      view.typed_group_events_path(parent_sheet.entry.id, entry.klass)
    end
  end
end
