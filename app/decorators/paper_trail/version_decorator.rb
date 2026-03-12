#  Copyright (c) 2012-2024, Pfadibewegung Schweiz. This file is part of
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
      if item_type == PeopleManager.sti_name
        return association_change_text_with_people_manager(changeset,
          item)
      end

      if item_type.include?("Translation") && main_type
        return changeset
      end

      I18n.t("version.association_change.#{item_class.name.underscore}.#{model.event}",
        default: :"version.association_change.#{model.event}",
        model: item_class.model_name.human,
        label: item ? label_with_fallback(item) : "",
        changeset: changeset)
    end

    def association_change_text_with_people_manager(changeset, _item) # rubocop:todo Metrics/CyclomaticComplexity, Metrics/AbcSize
      # Since PeopleManager entries are either created or destroyed, accessing changes makes sense
      changes = object.send(:object_changes_deserialized)
      manager_id = changes["manager_id"].compact.first
      managed_id = changes["managed_id"].compact.first

      key, label = if manager_id == main_id
        ["managed", Person.find_by(id: managed_id)&.person_name]
      elsif managed_id == main_id
        ["manager", Person.find_by(id: manager_id)&.person_name]
      end

      I18n.t("version.association_change.#{item_class.name.underscore}.#{model.event}.#{key}",
        default: :"version.association_change.#{model.event}",
        model: item_class.model_name.human,
        label: label || "(#{I18n.t("version.association_change.deleted_person")})",
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
      if model.event == "create" || model.event == "removed"
        # "removed" is a custom event for habtm where only the join table is destroyed;
        # actual records still exist, so we reify_existing.
        reify_exisiting
      else
        reify(model)
      end
    end

    def reify(version)
      return version.reify unless item_class.column_names.include?("type")

      model_type = YAML.safe_load(
        version.object,
        permitted_classes: [Date, Time, Symbol]
      )["type"]

      Object.const_defined?(model_type) ? version.reify : Wrapped.new(model_type)
    end

    def reify_exisiting
      model.item || build_new_instance
    end

    def build_new_instance
      clazz = type_class_from_changeset || item_class
      clazz.new(attrs_from_changeset)
    end

    def attrs_from_changeset = model.changeset.transform_values(&:last)

    def type_class_from_changeset = attrs_from_changeset["type"]&.safe_constantize

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
      {attr: attr_label(attr),
       from: normalize(attr, from),
       to: normalize(attr, to)}
    end

    def attr_label(attr)
      if item_type.include?("Translation")
        "#{main_type&.safe_constantize&.human_attribute_name(attr)} (#{item})"
      else
        (item_subtype&.safe_constantize || item_class).human_attribute_name(attr)
      end
    end

    def normalize(attr, value) # rubocop:todo Metrics/CyclomaticComplexity, Metrics/AbcSize
      if attr.to_s.end_with?("_id") && value.present?
        belongs_to_change_args(attr, value)
      elsif attr.to_s.end_with?("type") && value.present?
        value.safe_constantize&.model_name&.human
      elsif enum_translation(attr, value).present?
        enum_translation(attr, value)
      else
        col = item_class.columns_hash[attr.to_s]
        h.h(h.format_column(col.try(:type), value))
      end
    end

    def enum_translation(attr, value)
      item_i18n_key = item_subtype&.safe_constantize&.model_name&.i18n_key
      if I18n.exists?("activerecord.attributes.#{item_i18n_key}.#{attr.to_s.pluralize}.#{value}")
        I18n.t("activerecord.attributes.#{item_i18n_key}.#{attr.to_s.pluralize}.#{value}")
      end
    end

    def belongs_to_change_args(attr, value)
      association_name = attr.to_s.chomp("_id")

      if object.item.respond_to?(association_name)
        record = object.item.send(association_name)
        record.class.base_class.find_by(id: value).to_s if record
      else
        value
      end
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
