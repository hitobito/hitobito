#  Copyright (c) 2025, Puzzle ITC. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class PassDefinitionsController < CrudController
  self.nesting = Group
  self.permitted_attrs = [:name, :description, :template_key, :background_color]

  private

  def authorize_class
    authorize!(:index_pass_definitions, group)
  end

  alias_method :group, :parent
end
