# encoding: utf-8

#  Copyright (c) 2014 insieme Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module Dropdown
  module Event
    class ParticipantAdd < Dropdown::Base

      attr_reader :group, :event

      class << self
        def for_user(template, group, event, user)
          if user_participates_in?(user, event)
            new(template, group, event, I18n.t('event_decorator.applied'), :check).disabled_button
          else
            new(template, group, event, I18n.t('event_decorator.apply'), :check).to_s
          end
        end

        private

        def user_participates_in?(user, event)
          event.participations.where(person_id: user.id).exists?
        end
      end

      def initialize(template, group, event, label, icon, url_options = {})
        super(template, label, icon)
        @group = group
        @event = event
        init_items(url_options)
      end

      def to_s
        case items.size
        when 0 then nil
        when 1 then simple_button(items.first.url)
        else super
        end
      end

      def disabled_button
        simple_button('#', class: 'disabled')
      end

      private

      def simple_button(url, options = {})
        template.action_button(label, url, icon, options)
      end

      def init_items(url_options)
        event.participant_types.each do |type|
          opts = url_options.merge(event_role: { type: type.sti_name })
          link = participate_link(opts)
          add_item(translate(:as, role: type.label), link)
        end
      end

      def participate_link(opts)
        if opts[:for_someone_else]
          template.new_group_event_participation_path(group, event, opts)
        else
          template.contact_data_group_event_participations_path(group, event, opts)
        end
      end

    end
  end
end
