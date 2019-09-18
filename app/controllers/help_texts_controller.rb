# frozen_string_literal: true

#  Copyright (c) 2019, Pfadibewegung Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class HelpTextsController < SimpleCrudController
  self.permitted_attrs = [:context, :key, :body]

  self.sort_mappings = { body: 'help_text_translations.body' }

  before_render_form :load_select_items

  private

  def load_select_items
    form = HelpTexts::Form.new
    @contexts = form.list_contexts
    @keys = form.list_keys
  end
end
