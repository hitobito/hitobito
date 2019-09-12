# frozen_string_literal: true

#  Copyright (c) 2019, Pfadibewegung Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class HelpText::Form
  MODEL_DESCENDANTS_WHITELIST = [Event].freeze
  ACTION_KEYS = %w(action.index action.show action.new action.edit).freeze

  def list_contexts
    help_texts.map { |help_text| [help_text.context, help_text.context_human] }
              .sort_by(&:second)
  end

  def list_keys
    help_texts.map do |help_text|
      Hash[help_text.context, (ACTION_KEYS + help_text.field_keys).map do |key|
        help_text.key = key
        [key, help_text.key_human]
      end]
    end.reduce(&:merge)
  end

  private

  def help_texts
    @help_texts ||= routes.map { |route| help_texts_for_route(route) }
                          .flatten
                          .reject(&:nil?)
                          .uniq { |help_text| [help_text.controller_name, help_text.entry_class] }
  end

  def routes
    Rails.application.routes.routes
  end

  def help_texts_for_route(route)
    suppress(NameError, LoadError) do
      help_texts_for_controller_name(route.defaults[:controller])
    end
  end

  def help_texts_for_controller_name(controller_name)
    models(controller_name)
      .map { |model| model.model_name.to_s.underscore }
      .uniq
      .map { |entry_class| HelpText.new controller_name: controller_name, entry_class: entry_class }
      .each { |help_text| help_text.context_human } # Trigger possible invalid model exception
  end

  def models(controller_name)
    model = controller_name.classify.constantize
    MODEL_DESCENDANTS_WHITELIST.include?(model) ? (model.descendants + [model]) : [model]
  end
end
