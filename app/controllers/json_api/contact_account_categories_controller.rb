# frozen_string_literal: true

#  Copyright (c) 2026, Hitobito AG. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class JsonApi::ContactAccountCategoriesController < JsonApiController
  # :list_available instead of :index/:show, as those grant access to the admin interface
  def index
    authorize!(:list_available, ContactAccountCategory)
    super
  end

  def show
    authorize!(:list_available, ContactAccountCategory)
    super
  end
end
