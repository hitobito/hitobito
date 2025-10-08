#  Copyright (c) 2014 insieme Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module Dropdown
  module Event
    class ParticipantAdd < Dropdown::Base
      attr_reader :group, :event

      ICON = "user-plus"

      class << self
        def for_user(template, group, event, user)
          if user_participates_in?(user, event)
            new(template, group, event, I18n.t("event_decorator.applied")).disabled_button
          else
            new(template, group, event, I18n.t("event_decorator.apply")).to_s
          end
        end

        private

        def user_participates_in?(user, event)
          user.event_participations.map(&:event_id).include?(event.id)
        end
      end

      def initialize(template, group, event, label, icon = ICON, url_options = {})
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
        simple_button("#", class: "disabled")
      end

      private

      def simple_button(url, options = {})
        template.action_button(label, url, icon, options)
      end

      def init_items(url_options)
        if FeatureGate.enabled?("people.people_managers") && !url_options[:for_someone_else]
          return init_items_with_manageds(url_options)
        end

        event.participant_types.each do |type|
          opts = url_options.merge(event_role: {type: type.sti_name})
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

      # rubocop:disable Metrics/MethodLength, Metrics/AbcSize
      def init_items_with_manageds(url_options) # rubocop:todo Metrics/CyclomaticComplexity
        template.current_user.and_manageds.each do |person|
          opts = url_options.clone
          opts[:person_id] = person.id unless template.current_user == person

          disabled_message = disabled_message_for_person(person)
          if disabled_message.present?
            add_disabled_item(person, disabled_message)
          elsif event.participant_types.size > 1
            item = add_item(person.full_name, "#")

            item.sub_items = participant_types_sub_items(opts)
          else
            add_participant_item(person, opts)
          end
        end

        if register_new_managed?
          opts = url_options.merge(event_role: {type: event.participant_types.first.sti_name})
          add_item(
            translate(".register_new_managed"),
            template.contact_data_managed_group_event_participations_path(group, event, opts)
          )
        end
      end
      # rubocop:enable Metrics/MethodLength, Metrics/AbcSize

      def register_new_managed?
        event.external_applications? &&
          FeatureGate.enabled?("people.people_managers.self_service_managed_creation")
      end

      def disabled_message_for_person(participant)
        if ::Event::Participation.exists?(participant: participant, event: event)
          translate(:"disabled_messages.already_exists")
        elsif ::Ability.new(participant).cannot?(:show, event)
          translate(:"disabled_messages.cannot_see_event")
        end
      end

      def add_participant_item(person, opts)
        opts = opts.merge(event_role: {type: event.participant_types.first.sti_name})
        link = participate_link(opts)
        add_item(person.full_name, link)
      end

      def add_disabled_item(person, message)
        add_item("#{person.full_name} (#{message})", "#", disabled_msg: message)
      end
    end
  end
end
