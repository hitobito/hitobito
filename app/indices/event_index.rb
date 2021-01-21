# frozen_string_literal: true

#  Copyright (c) 2021, Pfadibewegung Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module EventIndex; end

ThinkingSphinx::Index.define_partial :event do
  indexes number, sortable: true
  indexes translations.name, as: :name, sortable: true

  indexes groups.name, as: :group_name
end
