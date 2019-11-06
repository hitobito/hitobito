# frozen_string_literal: true

#  Copyright (c) 2019, Pfadibewegung Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class HelpTexts::List
  COLUMN_BLACKLIST = %w(id created_at updated_at deleted_at).freeze
  ACTION_WHITELIST = %w(index edit new).freeze
  CONTROLLER_BLACKLIST = %w[
    async_downloads async_synchronizations errors healthz
    devise/passwords devise/registrations devise/sessions devise/tokens
    doorkeeper/authorizations doorkeeper/tokens
  ]

  def entries
    prepared_infos.each_with_object({}) do |(controller_name, action_name, model_class), memo|
      next unless model_class

      key   = HelpTexts::Entry.key(controller_name, model_class)
      entry = memo.fetch(key) do
        memo[key] = HelpTexts::Entry.new(controller_name, model_class)
      end

      entry.actions << action_name
      fields_for(model_name, entry.permitted_attrs).each do |field|
        entry.fields << field
      end
    end.values
  end

  def prepared_infos
    Rails.application.routes.routes.collect(&:defaults).compact.collect do |info|
      controller_name = info[:controller]
      action_name     = info[:action]
      next if CONTROLLER_BLACKLIST.include?(controller_name) || controller_name.blank?
      next unless ACTION_WHITELIST.include?(action_name)

      model_name      = info[:type] || controller_name.classify

      [controller_name, action_name,  model_for(model_name)]
    end.compact.uniq.sort_by(&:first)
  end

  def fields_for(model_name, permitted_attrs)
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
