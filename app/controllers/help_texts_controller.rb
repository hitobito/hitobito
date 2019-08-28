# frozen_string_literal: true

#  Copyright (c) 2019, Pfadibewegung Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_pbs.

class HelpTextsController < SimpleCrudController
  MODEL_NAME_BLACKLIST = ['ActiveRecord::', 'ActsAsTaggableOn::', 'Delayed::', 'Doorkeeper::',
                          'Group::', 'HABTM_', '::Role::', '::Translation', 'TableDisplay::'].freeze
  COLUMN_NAME_BLACKLIST = ['id'].freeze

  self.permitted_attrs = [:key, :body]

  self.sort_mappings = { body: 'help_text_translations.body' }

  before_render_form :available_keys


  private

  def list_entries
    super.list.sort_by(&:to_s)
  end

  def available_keys
    @available_keys ||= keys.reject { |key| existing_keys.include?(key) }
                            .map { |key| [key, HelpText.new(key: key).to_s] }
                            .sort_by(&:second)
  end

  def keys
    models.map do |model|
      column_keys = model.column_names
                         .reject { |col| COLUMN_NAME_BLACKLIST.find { |term| col.match(term) } }
      (column_keys + HelpText::VIEW_KEYS).map { |field| "#{model.name.underscore}.#{field}" }
    end.flatten(1)
  end

  def models
    models = ActiveRecord::Base.send(:subclasses)
    models += models.map { |c| c.send(:subclasses) }
    models.flatten.reject { |model| MODEL_NAME_BLACKLIST.find { |term| model.name.match(term) } }
  end

  def existing_keys
    @existing_keys ||= HelpText.select(:key).map(&:key) - [action_name == 'edit' && entry.key]
  end
end
