# frozen_string_literal: true

#  Copyright (c) 2019, Pfadibewegung Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module HelpTextsHelper

  def render_help_text(field = false)
    help_text = help_text_loader.find(field)
    return if help_text.nil?

    content_tag :div, class: "help-text #{help_text.dom_key}" do
      help_text.body && help_text.body.html_safe # rubocop:disable Rails/OutputSafety
    end
  end

  def render_help_text_trigger(field = false)
    help_text = help_text_loader.find(field)
    return '' if help_text.nil?

    content_tag :span, :class => 'help-text-trigger', 'data-key' => help_text.dom_key do
      content_tag :i, '', class: 'fa fa-info-circle'
    end
  end

  private

  def help_text_loader
    @help_text_loader ||= HelpText::Loader.new(controller_name, action_name, entry_class)
  end

  def entry_class
    suppress(NoMethodError) do
      return entries.first.model.class.to_s.underscore if action_name == 'index'
    end
    entry.model.class.to_s.underscore
  rescue NoMethodError
    entry.class.to_s.underscore
  rescue NameError
    nil
  end

end
