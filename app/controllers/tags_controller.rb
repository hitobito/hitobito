#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class TagsController < SimpleCrudController
  self.permitted_attrs = [:name]

  def self.model_class
    ActsAsTaggableOn::Tag
  end

  private

  def list_entries
    super.page(params[:page])
  end

  def index_path
    tags_path(returning: true)
  end
end
