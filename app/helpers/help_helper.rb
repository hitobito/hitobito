# frozen_string_literal: true

#  Copyright (c) 2019, Pfadibewegung Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module HelpHelper

  def render_help_text(field = action_name)
    return if help_text(field).nil?

    content_tag :div, class: "help-text #{help_text(field).dom_key}" do
      help_text(field).body.html_safe # rubocop:disable Rails/OutputSafety
    end
  end

  def render_help_text_trigger(field = action_name)
    return '' if help_text(field).nil?

    content_tag :span, :class => 'help-text-trigger', 'data-key' => help_text(field).dom_key do
      content_tag :i, '', class: 'fa fa-info-circle'
    end
  end

  private

  def help_texts
    @help_texts ||= load_help_texts
  end

  def load_help_texts
    model = action_name == 'index' ? entries.first : entry
    model_key = resolve_decorator(model).class.to_s.underscore
    HelpText.includes(:translations).where('key LIKE ?', "#{model_key}.%").all
  end

  def help_text(field = action_name)
    key = get_key(action_name == 'index' ? entries.first : entry, field)
    help_texts.find { |ht| ht.key == key }
  end

  def get_key(*args)
    ([resolve_decorator(args[0]).class.to_s.underscore] + args[1..-1]).join('.')
  end

  def resolve_decorator(entry)
    entry.respond_to?(:model) ? entry.model : entry
  end

end
