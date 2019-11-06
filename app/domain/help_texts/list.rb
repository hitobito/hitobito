# frozen_string_literal: true

#  Copyright (c) 2019, Pfadibewegung Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class HelpTexts::List
  CONTROLLER_BLACKLIST = %w[
    async_downloads async_synchronizations errors healthz
    devise/passwords devise/registrations devise/sessions devise/tokens
    doorkeeper/authorizations doorkeeper/tokens
  ]

  def entries
    prepared_infos.each_with_object({}) do |(controller_name, action_name, model_class), memo|
      key   = HelpTexts::Entry.key(controller_name, model_class)
      entry = memo.fetch(key) do
        memo[key] = HelpTexts::Entry.new(controller_name, model_class)
      end
      entry.actions << action_name
    end.values
  end

  def prepared_infos
    Rails.application.routes.routes.collect(&:defaults).compact.collect do |info|
      controller_name = info[:controller]
      next if CONTROLLER_BLACKLIST.include?(controller_name) || controller_name.blank?

      action_name     = info[:action]
      model_class     = model_for(info[:type] || controller_name.classify)
      next unless model_class

      [controller_name, action_name, model_class]
    end.compact.uniq.sort_by(&:first)
  end

  def model_for(model_name)
    @models ||= {}

    @models.fetch(model_name) do
      model = model_name.constantize rescue nil
      model if model && model <= ActiveRecord::Base
    end.presence
  end

end
