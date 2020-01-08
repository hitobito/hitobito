# frozen_string_literal: true

#  Copyright (c) 2019, Pfadibewegung Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_pbs.

class HelpTexts::Renderer

  attr_reader :template

  delegate :dom_id, :content_tag, :icon, :action_name, :params, :model_class, to: :template

  def initialize(template, entry = nil)
    @template = template
    @entry = entry
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

  def render_field(key)
    with_help_text(key, :field) do |help_text|
      render_trigger(help_text) + render_text(help_text)
    end
  end

  def entry
    @entry ||= derive_entry
  end

  def safe_html(text, tags: %w(h1 h2 h3 h4 h5 h6 b i u blockquote ul ol li a))
    template.sanitize(text, tags: tags)
  end

  private

  def render_text(help_text)
    content_tag(:div, class: "help-text #{dom_id(help_text)}") do
      help_text.body && safe_html(help_text.body)
    end
  end

  def render_trigger(help_text)
    content_tag(:span, class: 'help-text-trigger', data: { key: dom_id(help_text) }) do
      icon('info-circle')
    end
  end

  def with_help_text(key, kind)
    texts = help_texts.select { |ht| ht.name == key.to_s && ht.kind == kind.to_s }.index_by(&:model)

    if texts.present?
      text = texts[entry.class.to_s.underscore] || texts[entry.class.base_class.to_s.underscore]
      yield text if text
    end
  end

  def controller_name
    template.controller.class.to_s.underscore.gsub('_controller', '')
  end

  def derive_entry
    if params[:type]
      params[:type].constantize.new
    elsif action_name == 'index'
      model_class.new
    else
      entry = template.controller.send(:entry)
      entry.try(:decorated?) ? entry.model : entry
    end
  end

  def help_texts
    @help_texts ||= HelpText.includes(:translations).where(controller: controller_name)
  end
end
