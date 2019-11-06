# frozen_string_literal: true

#  Copyright (c) 2019, Pfadibewegung Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_pbs.

class HelpTexts::Renderer

  attr_reader :template

  delegate :dom_id, :content_tag, :icon, :controller_name, :action_name, to: :template

  def initialize(template)
    @template = template
  end

  def action_trigger
    with_help_text(action_name, :action) do |help_text|
      render_trigger(help_text)
    end
  end

  def action_text
    with_help_text(action_name, :action) do |help_text|
      render_text(help_text)
    end
  end

  def render_field(key, entry = nil)
    with_help_text(key, :field, entry) do |help_text|
      render_trigger(help_text) + render_text(help_text)
    end
  end

  private

  def render_text(help_text)
    content_tag(:div, class: "help-text #{dom_id(help_text)}") do
      help_text.body && help_text.body.html_safe # rubocop:disable Rails/OutputSafety
    end
  end

  def render_trigger(help_text)
    content_tag(:span, class: 'help-text-trigger', data: { key: dom_id(help_text) }) do
      icon('info-circle')
    end
  end

  def with_help_text(key, kind, entry = nil)
    texts = help_texts.select { |ht| ht.name == key.to_s && ht.kind == kind.to_s }.index_by(&:model)
    text = if entry
             texts[entry.class.to_s.underscore] || texts[entry.class.base_class.to_s.underscore]
           else
             texts.values.first
           end
    yield text if text
  end

  def help_texts
    @help_texts ||= HelpText.includes(:translations).where(controller: controller_name)
  end
end
