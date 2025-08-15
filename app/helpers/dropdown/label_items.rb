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
      @households = item_options.delete(:households)
      @item_options = item_options.reverse_merge(class: "export-label-format")
    end

    def add
      label_item = add_item(translate(:labels), main_label_link)
      add_last_used_format_item(label_item)
      add_label_format_items(label_item)
      add_households_labels_option_items(label_item)
    end

    def main_label_link
      if user&.last_label_format_id
        export_label_format_path(user.last_label_format_id)
      else
        "#"
      end
    end

    def add_last_used_format_item(parent)
      if last_label_format?
        last_format = user.last_label_format
        parent.sub_items << Title.new(dropdown.template.t("dropdown.last_used"))
        parent.sub_items << Item.new(last_format.to_s, export_label_format_path(last_format.id),
          class: "export-label-format")
        parent.sub_items << Divider.new
      end
    end

    def last_label_format?
      user&.last_label_format_id? && LabelFormat.for_person(user).exists?
    end

    def add_label_format_items(parent)
      if additional_address?
        add_label_format_items_with_additional_address(parent)
      else
        add_label_format_items_without_additional_address(parent)
      end
    end

    def add_label_format_items_with_additional_address(parent) # rubocop:todo Metrics/AbcSize
      LabelFormat.list.for_person(user).each do |label_format|
        format_item = Item.new(label_format.to_s, "#")
        parent.sub_items << format_item

        types_with_labels = AdditionalAddress.predefined_labels.map { |l|
          [l, AdditionalAddress.translate_label(l)]
        }
        types_with_labels.unshift([:main,
          I18n.t(".additional_address.main", scope: self.class.to_s.underscore)])
        types_with_labels.each do |address_type, label|
          format_item.sub_items << add_label_format_item(label_format, label:, address_type:)
        end
      end
    end

    def add_label_format_items_without_additional_address(parent)
      LabelFormat.list.for_person(user).each do |label_format|
        parent.sub_items << add_label_format_item(label_format)
      end
    end

    def add_label_format_item(label_format, label: label_format, **params)
      Item.new(label, export_label_format_path(label_format.id, **params),
        class: "export-label-format")
    end

    def add_households_labels_option_items(parent)
      if @households
        parent.sub_items << Divider.new
        parent.sub_items << ToggleHouseholdsLabelsItem.new(dropdown.template)
      end
    end

    def export_label_format_path(label_format_id, address_type: nil)
      households = ToggleHouseholdsLabelsItem::DEFAULT_STATE if @households
      params.merge(format: :pdf, label_format_id:, household: households,
        address_type:).compact_blank
    end

    class ToggleHouseholdsLabelsItem < Dropdown::Base
      DEFAULT_STATE = true

      def initialize(template)
        super(template, template.t("dropdown/people_export.household_option"), :plus)
      end

      def render(template)
        template.content_tag(:li) do
          template.link_to("#", id: "toggle-household-labels") do
            render_checkbox(template)
          end
        end
      end

      def render_checkbox(template)
        template.content_tag(:div, class: "checkbox dropdown-item") do
          template.content_tag(:label, for: :household) do
            template.safe_join([
              template.check_box_tag(:household, "1", DEFAULT_STATE, class: "me-2"),
              template.t("dropdown/people_export.household_option")
            ].compact)
          end
        end
      end
    end

    def additional_address? = FeatureGate.enabled?("additional_address")
  end
end
