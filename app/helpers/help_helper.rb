# frozen_string_literal: true

#  Copyright (c) 2019, Pfadibewegung Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module HelpHelper

  def help_text_for_field(field)
    help_texts.find { |ht| ht.key.split('.').last == field.to_s }
  end

  def render_help_text
    return if help_text.nil?

    content_tag :div, class: "help-text alert alert-info #{help_text.dom_key}" do
      help_text.body.html_safe # rubocop:disable Rails/OutputSafety
    end
  end

  def render_help_text_trigger
    return '' if help_text.nil?

    content_tag :span, :class => 'help-text-trigger', 'data-key' => help_text.dom_key do
      content_tag :i, '', class: 'fa fa-info-circle'
    end
  end

  private

  def help_text
    get_help_text(action_name == 'index' ? entries.first : entry, action_name)
  end

  def get_help_text(*args)
    help_text_for_key(get_key(*args))
  end

  def help_text_for_key(key)
    help_texts.find { |ht| ht.key == key }
  end

  def help_texts
    @help_texts ||= load_help_texts
  end

  def load_help_texts
    model = action_name == 'index' ? entries.first : entry
    model_key = resolve_decorator(model).class.to_s.underscore
    HelpText.includes(:translations).where('key LIKE ?', "#{model_key}.%").all
  end

  def get_key(*args)
    ([resolve_decorator(args[0]).class.to_s.underscore] + args[1..-1]).join('.')
  end

  def resolve_decorator(entry)
    entry.respond_to?(:model) ? entry.model : entry
  end

end
