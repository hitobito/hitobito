# frozen_string_literal: true

module TagListsHelper

  def available_tags_checkboxes(tags)
    safe_join(tags.map do |tag, count|
      content_tag(:div, class: 'control-group  available-tag') do
        tag_checkbox(tag, count)
      end
    end, '')
  end

  def format_tag_category(category)
    case category
    when :other
      t('tags.categories.other')
    when :category_validation
      t('tags.categories.validation')
    else
      category
    end
  end

  def format_tag_name(tag)
    PersonTags::Translator.new.translate(tag)
  end

  private

  def tag_checkbox(tag, count)
    label_tag(nil, class: 'checkbox ') do
      out = check_box_tag("tags[]", tag.name, false)
      out << tag
      out << content_tag(:div, class: 'role-count') do
        count.to_s
      end
      out.html_safe
    end
  end
end
