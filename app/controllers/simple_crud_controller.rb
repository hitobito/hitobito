#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

# A Crud controller without a show action.
# Handles paranoid models as well.
class SimpleCrudController < CrudController


  def create
    super(location: index_path)
  end

  def update
    super(location: index_path)
  end

  private

  def assign_attributes
    super
    entry.deleted_at = nil if model_class.paranoid?
  end

end
