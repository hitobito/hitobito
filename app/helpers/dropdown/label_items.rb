# frozen_string_literal: true

#  Copyright (c) 2012-2022, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module Dropdown
  class LabelItems
    attr_reader :dropdown, :item_options

    delegate :add_item, :translate, :user, :params, to: :dropdown

    def initialize(dropdown, item_options = {})
      @dropdown = dropdown
      @households = item_options.delete(:households)
      @item_options = item_options.reverse_merge(class: 'export-label-format')
    end

    def add
      label_item = add_item(translate(:labels), main_label_link)
      add_last_used_format_item(label_item)
      add_label_format_items(label_item)
      add_households_labels_option_items(label_item)
    end

    private

    def main_label_link
      if user&.last_label_format_id
        export_label_format_path(user.last_label_format_id)
      else
        '#'
      end
    end

    def add_last_used_format_item(parent)
      if last_label_format?
        last_format = user.last_label_format
        parent.sub_items << Title.new(dropdown.template.t('dropdown.last_used'))
        parent.sub_items << Item.new(last_format.to_s,
                                     export_label_format_path(last_format.id),
                                     class: 'export-label-format')
        parent.sub_items << Divider.new
      end
    end

    def last_label_format?
      user&.last_label_format_id? && LabelFormat.for_person(user).exists?
    end

    def add_label_format_items(parent)
      LabelFormat.list.for_person(user).each do |label_format|
        parent.sub_items << Item.new(label_format, export_label_format_path(label_format.id),
                                     class: 'export-label-format')
      end
    end

    def add_households_labels_option_items(parent)
      if @households
        parent.sub_items << Divider.new
        parent.sub_items << household_label_checkbox
      end
    end

    def export_label_format_path(id)
      households = household_labels_default if @households
      params.merge(format: :pdf, label_format_id: id,
                   household: households)
    end

    def household_label_checkbox
      template = dropdown.template
      label = template.t('dropdown/people_export.household_option')
      id = :household
      ToggleParamItem.new(template, id, label, checked: household_labels_default)
    end

    def household_labels_default
      true
    end

  end
end
