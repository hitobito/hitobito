# frozen_string_literal: true

#  Copyright (c) 2019, Pfadibewegung Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class HelpTexts::List
  COLUMN_BLACKLIST = %w(id created_at updated_at deleted_at).freeze
  CONTROLLER_BLACKLIST = %w(healthz async_downloads async_synchronizations)

  include Enumerable

  def to_a
    @list ||= build_list
  end

  def texts
    list.collect do |controller_name, key, model_class|
      HelpText.new(controller_name: controller_name, key: key, entry_class: model_class)
    end
  end

  def build_list
    prepared_infos.each_with_object([]) do |(controller_name, action_name, model_name), list|
      list << [controller_name, "action.#{action_name}", model_name]

      fields_for(model_name).each do |field|
        list << [controller_name, "field.#{field}", model_name]
      end

    end.compact.uniq
  end

  def prepared_infos
    Rails.application.routes.routes.collect(&:defaults).compact.collect do |info|
      controller_name = info[:controller]
      next if CONTROLLER_BLACKLIST.include?(controller_name) || controller_name.blank?

      action_name     = info[:action]
      model_name      = info[:type] || controller_name.classify

      [controller_name, action_name,  model_for(model_name) ? model_name : nil]
    end.compact.uniq.sort_by(&:first)
  end

  def fields_for(model_name)
    @seen ||= []

    return [] unless model_name
    return [] if @seen.include?(model_name)

    (model_for(model_name).column_names.sort - COLUMN_BLACKLIST).tap do
      @seen << model_name
    end
  end

  def model_for(model_name)
    @models ||= {}

    @models.fetch(model_name) do
      model = model_name.constantize rescue nil
      model && model <= ActiveRecord::Base ? model : false
    end.presence
  end

end
