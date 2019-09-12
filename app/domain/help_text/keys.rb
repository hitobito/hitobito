# frozen_string_literal: true

#  Copyright (c) 2019, Pfadibewegung Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_pbs.

class HelpText::Keys
  ACTION_KEYS = %w(action.index action.show action.new action.edit).freeze

  def self.list(contexts)
    Hash[contexts.collect do |context_key, _|
      [
        context_key,
        ACTION_KEYS.map do |action_key|
          [action_key, HelpText.human_attribute_name("key.#{action_key.split('.').last}")]
        end + fields_for(context_key)
      ]
    end]
  end

  def self.fields_for(context_key)
    model = context_key.split('--').last.classify.constantize
    model.column_names.map do |column_name|
      ["field.#{column_name}", "Feld «#{model.human_attribute_name(column_name)}»"]
    end
  rescue NameError
    []
  end
end
