# frozen_string_literal: true

# Copyright (c) 2026. BienenSchweiz. This file is part of
# hitobito and licensed under the Affero General Public License version 3
# or later. See the COPYING file at the top-level directory or at
# https://github.com/hitobito/hitobito

class PersonalDocumentLabelsController < CrudController
  self.permitted_attrs = [:name]

  def create
    super(location: index_path)
  end

  def update
    super(location: index_path)
  end
end
