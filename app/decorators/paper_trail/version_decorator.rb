# encoding: utf-8

#  Copyright (c) 2012-2013, Pfadibewegung Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module PaperTrail
  class VersionDecorator < ApplicationDecorator

    def header
      (author ? [created_at, translate(:by, author: author)].join(' ') : created_at).html_safe
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
      else
        changeset_lines
      end
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
      attr_label = item_class.human_attribute_name(attr)
      if from.present? && to.present?
        I18n.t("version.attribute_change.from_to", attr: attr_label, from: normalize(from), to: normalize(to))
      elsif from.present?
        I18n.t("version.attribute_change.from", attr: attr_label, from: normalize(from))
      elsif to.present?
        I18n.t("version.attribute_change.to", attr: attr_label, to: normalize(to))
      else
        ''
      end.html_safe
    end

    def association_change
      changeset = model.event == 'update' ? changeset_list : nil

      I18n.t("version.association_change.#{model.event}",
             model: item_class.model_name.human,
             label: reifyed_item.to_s,
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
          version.reify
        else
          model.item
        end
      else
        model.reify
      end
    end

    def normalize(value)
      h.h(h.f(value))
    end
  end
end
