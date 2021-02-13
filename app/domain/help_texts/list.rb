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

  def order_statement
    prepared_infos.collect(&:last).uniq.sort_by { |model_class|
      model_class.model_name.human
    }.each_with_index.inject("CASE model") { |sql, (model_class, index)|
      sql += " WHEN '#{model_class.to_s.underscore}' THEN #{index}"
    } + " END"
  end

  def entries
    prepared_infos.each_with_object({}) { |(controller_name, action_name, model_class), memo|
      key = HelpTexts::Entry.key(controller_name, model_class)
      entry = memo.fetch(key) {
        memo[key] = HelpTexts::Entry.new(controller_name, model_class, help_texts(key))
      }
      entry.action_names << action_name
      if entry.controller_name == "events" && entry.model_class != Event
        entry.action_names << "new" << "show" << "edit"
      end
    }.values
  end

  def help_texts(key)
    @help_texts ||= HelpText.all.each_with_object({}) { |help_text, memo|
      entry_key = HelpTexts::Entry.key(help_text.controller, help_text.model)
      kind_key = help_text.kind.to_sym

      memo[entry_key] ||= {field: [], action: []}
      memo[entry_key][kind_key] << help_text.name
    }
    @help_texts[key]
  end

  def prepared_infos
    Rails.application.routes.routes.collect(&:defaults).compact.collect { |info|
      controller_name = info[:controller]
      next if CONTROLLER_BLACKLIST.include?(controller_name) || controller_name.blank?

      action_name = info[:action]
      model_class = model_for(info[:type] || controller_name.classify)
      next unless model_class

      [controller_name, action_name, model_class]
    }.compact.uniq.sort_by(&:first)
  end

  def model_for(model_name)
    @models ||= {}

    @models.fetch(model_name) {
      model = begin
                model_name.constantize
              rescue
                nil
              end
      model if model && model <= ActiveRecord::Base
    }.presence
  end
end
