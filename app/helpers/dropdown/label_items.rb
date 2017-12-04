# encoding: utf-8

#  Copyright (c) 2012-2017, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module Dropdown
  class LabelItems
    attr_reader :dropdown, :item_options

    delegate :add_item, :translate, :user, :params, to: :dropdown

    def initialize(dropdown, item_options = {})
      @dropdown = dropdown
      @condense_labels = item_options.delete(:condense_labels)
      @item_options = item_options.reverse_merge(target: :new,
                                                 class: 'export-label-format')
    end

    def add
      label_item = add_item(translate(:labels), main_label_link)
      add_last_used_format_item(label_item)
      add_label_format_items(label_item)
      add_condensed_labels_option_items(label_item) if @condense_labels
    end

    def main_label_link
      if user.last_label_format_id
        export_label_format_path(user.last_label_format_id)
      else
        '#'
      end
    end

    def add_last_used_format_item(parent)
      if user.last_label_format_id?
        last_format = user.last_label_format
        parent.sub_items << Item.new(last_format.to_s,
                                     export_label_format_path(last_format.id),
                                     item_options)
        parent.sub_items << Divider.new
      end
    end

    def add_label_format_items(parent)
      LabelFormat.list.for_person(user).each do |label_format|
        parent.sub_items << Item.new(label_format,
                                     export_label_format_path(label_format.id),
                                     item_options)
      end
    end

    def add_condensed_labels_option_items(parent)
      parent.sub_items << Divider.new
      parent.sub_items << ToggleCondensedLabelsItem.new(dropdown.template)
    end

    def export_label_format_path(id)
      params.merge(format: :pdf, label_format_id: id,
                   condense_labels: ToggleCondensedLabelsItem::DEFAULT_STATE)
    end


    class ToggleCondensedLabelsItem < Dropdown::Base
      DEFAULT_STATE = false

      def initialize(template)
        super(template, template.t('dropdown/people_export.condense_labels'), :plus)
      end

      def render(template)
        template.content_tag(:li) do
          template.link_to('#', id: 'toggle-condense-labels') do
            render_checkbox(template)
          end
        end
      end

      def render_checkbox(template)
        template.content_tag(:div, class: 'checkbox') do
          template.content_tag(:label, for: :condense) do
            template.safe_join([
              template.check_box_tag(:condense, '1', DEFAULT_STATE),
              template.t('dropdown/people_export.condense_labels'),
              template.content_tag(:p, template.t('dropdown/people_export.condense_labels_hint'),
                                   class: 'help-text')
            ].compact)
          end
        end
      end
    end
  end
end

