# frozen_string_literal: true

module PersonTags
  class Translator
    def possible_tags
      ActsAsTaggableOn::Tag.all.order(:name).collect do |tag|
        [translate(tag, include_category: true), tag.name, tag.id]
      end
    end

    def translate(tag, include_category: false)
      category = tag.category
      name = tag.name_without_category
      if translatable_tags[category]&.include?(name)
        return I18n.t("person.tags.tag.#{category}.#{name}")
      end

      include_category ? tag.name : tag.name_without_category
    end

    private

    def translatable_tags
      {category_validation: %w[email_primary_invalid email_additional_invalid address_invalid]}
    end
  end
end
