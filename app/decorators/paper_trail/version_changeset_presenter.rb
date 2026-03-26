#  Copyright (c) 2026, Hitobito AG. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module PaperTrail
  class VersionChangesetPresenter
    attr_reader :version, :h

    delegate :item, :item_type, :item_subtype, :main_id, :main_type, to: :version

    def initialize(version, view_context)
      @version = version
      @h = view_context
    end

    def render
      h.safe_join(version.changeset) do |attr, (from, to)|
        h.content_tag(:div, attribute_change(attr, from, to))
      end
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

    private

    def attribute_change_key(from, to)
      from_valid = valid_value?(from)
      to_valid = valid_value?(to)

      return "from_to" if from_valid && to_valid
      return "from" if from_valid
      "to" if to_valid
    end

    def attribute_change_args(attr, from, to)
      {attr: ERB::Util.html_escape(attr_label(attr)),
       from: ERB::Util.html_escape(normalize(attr, from)),
       to: ERB::Util.html_escape(normalize(attr, to))}
    end

    def attr_label(attr)
      if item_type.include?("Translation")
        translation_label(attr)
      else
        (item_subtype&.safe_constantize || item_class).human_attribute_name(attr)
      end
    end

    def translation_label(attr)
      # globalized_model knows the sti model class to be able to load sti translations
      # as well as being able to load translations for translated attributes even if
      # the main_type is not the globalized_model.
      attribute_label = item.globalized_model.class.human_attribute_name(attr)
      if item.globalized_model.is_a?(main_type.safe_constantize)
        "#{attribute_label} (#{item})"
      else
        "#{attribute_label} (#{item}) #{I18n.t("global.from")} #{item.globalized_model}"
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
        h.format_column(col.try(:type), value)
      end
    end

    # We load both keys and check for a subtype translation, if that does not exist, we fallback
    # to a base type translation
    def enum_translation(attr, value)
      subtype_key = i18n_key(item_subtype)
      base_key = i18n_key(item_type)
      attr_path = "#{attr.to_s.pluralize}.#{value}"

      if subtype_key && I18n.exists?("activerecord.attributes.#{subtype_key}.#{attr_path}")
        I18n.t("activerecord.attributes.#{subtype_key}.#{attr_path}")
      elsif base_key && I18n.exists?("activerecord.attributes.#{base_key}.#{attr_path}")
        I18n.t("activerecord.attributes.#{base_key}.#{attr_path}")
      end
    end

    def i18n_key(type)
      type&.underscore
    end

    def belongs_to_change_args(attr, value)
      association_name = attr.to_s.chomp("_id")

      if item.respond_to?(association_name)
        record = item.send(association_name)
        record.class.base_class.find_by(id: value).to_s if record
      else
        value
      end
    end

    def item_class = @item_class ||= version.item_type.constantize

    def valid_value?(value) = value.present? && value != ","
  end
end
