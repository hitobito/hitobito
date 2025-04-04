#  Copyright (c) 2012-2024, Pfadibewegung Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module PaperTrail
  class VersionDecorator < ApplicationDecorator
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
      if model.main.present? && model.main_type == "Person"
        h.link_to_if(can?(:show, model.main), model.main.to_s, h.person_path(model.main.id))
      end
    end

    def author
      if model.version_author.present?
        author_id = model.version_author
        author_type = model.whodunnit_type
        if author_type == ServiceToken.sti_name
          author_service_token(author_id)
        else
          author_person(author_id)
        end
      end
    end

    def author_person(author_id)
      person = Person.where(id: author_id).first
      if person
        h.link_to_if(can?(:show, person), person.to_s, h.person_path(person.id))
      end
    end

    def author_service_token(author_id)
      token = ServiceToken.where(id: author_id).first
      if token
        layer_id = token.layer_group_id
        label = author_service_token_label(token)
        h.link_to_if(can?(:show, token), label, h.group_service_token_path(layer_id, token.id))
      else
        I18n.t("version.deleted_service_token", model_name: ServiceToken.model_name.human)
      end
    end

    def author_service_token_label(token)
      "#{ServiceToken.model_name.human}: #{token}"
    end

    def changes
      if item_type != main_type
        content_tag(:div, association_change)
      elsif event.to_sym.eql?(:person_merge)
        person_merge_list
      elsif custom_event_action?
        custom_event_changes
      else
        changeset_lines
      end
    end

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

    def changeset_lines
      safe_join(model.changeset) do |attr, (from, to)|
        content_tag(:div, attribute_change(attr, from, to))
      end
    end

    def changeset_list
      safe_join(model.changeset, ", ") do |attr, (from, to)|
        attribute_change(attr, from, to)
      end
    end

    def person_merge_list
      content = content_tag(:div, t_event).html_safe
      content += safe_join(YAML.load(model.object_changes, permitted_classes: [Date, Time, Symbol])) do |line|
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

    def attribute_change(attr, from, to)
      key = attribute_change_key(from, to)
      if key
        I18n.t("version.attribute_change.#{key}",
               **attribute_change_args(attr, from, to))
          .html_safe
      else
        ""
      end
    end

    def association_change
      changeset = (model.event == "update") ? changeset_list : nil
      item = reifyed_item

      text = association_change_text(changeset, item)

      h.sanitize(text, tags: %w[i])
    end

    private

    def association_change_text(changeset, item)
      # used to overwrite in youth wagon
      I18n.t("version.association_change.#{item_class.name.underscore}.#{model.event}",
        default: :"version.association_change.#{model.event}",
        model: item_class.model_name.human,
        label: item ? label_with_fallback(item) : "",
        changeset: changeset)
    end

    def label_with_fallback(item)
      item.to_s(:long)
    rescue
      I18n.t("global.unknown")
    end

    def item_class
      @item_class ||= model.item_type.constantize
    end

    def reifyed_item
      if model.event == "create"
        version = model.next
        if version
          reify(version)
        else
          model.item
        end
      else
        reify(model)
      end
    end

    def reify(version)
      item_type = version.item_type.constantize
      return version.reify unless item_type.column_names.include?("type")

      model_type = YAML.safe_load(
        version.object,
        permitted_classes: [Date, Time, Symbol]
      )["type"]

      Object.const_defined?(model_type) ? version.reify : Wrapped.new(model_type)
    end

    def attribute_change_key(from, to)
      if from.present? && to.present?
        "from_to"
      elsif from.present?
        "from"
      elsif to.present?
        "to"
      end
    end

    def attribute_change_args(attr, from, to)
      {attr: item_class.human_attribute_name(attr),
       from: normalize(attr, from),
       to: normalize(attr, to)}
    end

    def normalize(attr, value)
      col = item_class.columns_hash[attr.to_s]
      h.h(h.format_column(col.try(:type), value))
    end

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
