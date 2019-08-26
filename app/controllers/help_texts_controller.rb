# frozen_string_literal: true

#  Copyright (c) 2019, Pfadibewegung Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_pbs.

class HelpTextsController < SimpleCrudController

  self.permitted_attrs = [:key, :body]

  self.sort_mappings = { body: 'help_text_translations.body' }


  private

  def list_entries
    super.list
  end

end
