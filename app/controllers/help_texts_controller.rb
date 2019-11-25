# frozen_string_literal: true

#  Copyright (c) 2019, Pfadibewegung Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class HelpTextsController < SimpleCrudController
  self.permitted_attrs = [:context, :key, :body]

  self.sort_mappings = { body: 'help_text_translations.body' }

  self.skip_translate_inheritable = true

  before_render_form :load_select_items

  private

  def entries
    super.list.includes(:translations).page(params[:page])
  end

  def load_select_items
    entries = HelpTexts::List.new.entries.select(&:present?)

    @contexts = entries.collect do |entry|
      [entry.key, entry.to_s]
    end.sort_by(&:second)

    @keys = entries.each_with_object({}) do |entry, memo|
      memo[entry.key] = entry.grouped
    end
  end
end
