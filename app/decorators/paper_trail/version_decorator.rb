#  Copyright (c) 2026, Hitobito AG. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module PaperTrail
  class VersionDecorator < ApplicationDecorator # rubocop:disable Metrics/ClassLength
    def header(include_changed_object: false)
      fields = [created_at]
      if author
        fields += [translate(:by, author: author)]
      end
      if include_changed_object
        fields = [changed_object] + fields
      end
      fields.join(h.tag(:br)).html_safe
    end

    def created_at
      h.l(model.created_at, format: :long)
    end

    def changed_object
      return unless model.main

      case model.main_type
      when "Person"
        link_to_changed_object(h.person_path(model.main.id))
      when "Group"
        link_to_changed_object(h.group_path(model.main.id))
      end
    end

    def link_to_changed_object(path)
      h.content_tag(:strong,
        h.link_to_if(can?(:show, model.main), model.main.to_s, path))
    end

    def author
      PaperTrail::VersionAuthorPresenter.new(model, h).render
    end

    def changes
      if item_type != main_type
        PaperTrail::VersionAssociationChangePresenter.new(model, h).render
      elsif event.to_sym.eql?(:person_merge)
        person_merge_list
      elsif custom_event_action?
        custom_event_changes
      else
        PaperTrail::VersionChangesetPresenter.new(model, h).render
      end
    end

    private

    def custom_event_action?
      !item_class.paper_trail_options[:on].include?(event.to_sym)
    end

    def custom_event_changes
      content_tag(:div,
        t_event(user: whodunnit,
          item: item,
          object_name: object.object.presence,
          object_changes: object_changes))
    end

    def person_merge_list
      content = content_tag(:div, t_event).html_safe
      content += safe_join(YAML.load(model.object_changes,
        permitted_classes: [Date, Time, Symbol])) do |line|
        person_merge_value(line)
      end
      content
    end

    def person_merge_value(line)
      attr, value = line
      attr = t_person(attr)
      if value.is_a?(Array)
        c = content_tag(:div, "#{attr}:")
        value.each do |v|
          c += content_tag(:div, v)
        end
        c
      else
        content_tag(:div, "#{attr}: #{value}")
      end
    end

    def t_event(user: nil, item: nil, object_changes: nil, object_name: nil)
      I18n.t("version.#{event}",
        user: user,
        item: item,
        object_name: object_name,
        object_changes: object_changes)
    end

    def t_person(attr)
      I18n.t("activerecord.attributes.person.#{attr}")
    end

    def item_class = @item_class ||= model.item_type.constantize

    class Wrapped
      def initialize(string)
        @string = string
      end

      def to_s(_arg)
        @string
      end
    end
  end
end
