# encoding: utf-8

#  Copyright (c) 2012-2013, Pfadibewegung Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module PaperTrail
  class VersionDecorator < ApplicationDecorator

    def header
      if author
        [created_at, translate(:by, author: author)].join(h.tag(:br)).html_safe
      else
        created_at
      end
    end

    def created_at
      h.l(model.created_at, format: :long)
    end

    def author
      if model.version_author.present?
        person = Person.where(id: model.version_author).first
        if person
          h.link_to_if(can?(:show, person), person.to_s, h.person_path(person.id))
        end
      end
    end

    def changes
      if item_type != main_type
        content_tag(:div, association_change)
      elsif !item_class.paper_trail_options[:on].include?(event.to_sym)
        custom_event_changes
      else
        changeset_lines
      end
    end

    def custom_event_changes
      content_tag(:div, 
                  I18n.t("version.#{event}", 
                  user: whodunnit, 
                  item: item, 
                  object_changes: object_changes))
    end

    def changeset_lines
      safe_join(model.changeset) do |attr, (from, to)|
        content_tag(:div, attribute_change(attr, from, to))
      end
    end

    def changeset_list
      safe_join(model.changeset, ', ') do |attr, (from, to)|
        attribute_change(attr, from, to)
      end
    end

    def attribute_change(attr, from, to)
      key = attribute_change_key(from, to)
      if key
        I18n.t("version.attribute_change.#{key}",
               attribute_change_args(attr, from, to)).
             html_safe
      else
        ''
      end
    end

    def association_change
      changeset = model.event == 'update' ? changeset_list : nil
      item = reifyed_item

      I18n.t("version.association_change.#{item_class.name.underscore}.#{model.event}",
             default: :"version.association_change.#{model.event}",
             model: item_class.model_name.human,
             label: item ? item.to_s(:long) : '',
             changeset: changeset).html_safe
    end

    private

    def item_class
      @item_class ||= model.item_type.constantize
    end

    def reifyed_item
      if model.event == 'create'
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
      return version.reify unless item_type.column_names.include?('type')
      model_type = YAML.load(version.object)['type']
      Object.const_defined?(model_type) ? version.reify : Wrapped.new(model_type)
    end

    def attribute_change_key(from, to)
      if from.present? && to.present?
        'from_to'
      elsif from.present?
        'from'
      elsif to.present?
        'to'
      end
    end

    def attribute_change_args(attr, from, to)
      { attr: item_class.human_attribute_name(attr),
        from: normalize(attr, from),
        to: normalize(attr, to) }
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
