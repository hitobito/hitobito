# frozen_string_literal: true

#  Copyright (c) 2019, Pfadibewegung Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_pbs.

class HelpText::Contexts
  MODEL_DESCENDANTS_WHITELIST = [Event].freeze

  def self.list
    context_list.map do |context_list_item|
      [key_for(context_list_item), human_name_for(context_list_item)]
    end.sort_by(&:second)
  end

  def self.context_list
    context_list = Rails.application.routes.routes.map do |route|
      context_list_items_for(route)
    end.flatten
    context_list.uniq.reject(&:nil?)
  end

  def self.context_list_items_for(route)
    model = route.defaults[:controller].classify.constantize
    models = MODEL_DESCENDANTS_WHITELIST.include?(model) ? (model.descendants + [model]) : [model]
    models.map do |model_or_descendant|
      context_list_item_for(route.defaults[:controller], model, model_or_descendant)
    end
  rescue NameError, LoadError
    nil
  end

  def self.context_list_item_for(name, model, model_or_descendant)
    {
      controller_name: name,
      controller_name_human: model.model_name.human,
      entry_class: model_or_descendant.model_name.to_s.underscore,
      entry_class_human: model_or_descendant.model_name.human
    }
  end

  def self.key_for(context_list_item)
    "#{context_list_item[:controller_name]}--#{context_list_item[:entry_class]}"
  end

  def self.human_name_for(context_list_item)
    if context_list_item[:controller_name_human] != context_list_item[:entry_class_human]
      "#{context_list_item[:controller_name_human]} (#{context_list_item[:entry_class_human]})"
    else
      context_list_item[:controller_name_human]
    end
  end
end
