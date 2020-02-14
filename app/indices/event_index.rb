# encoding: utf-8

#  Copyright (c) 2017, Pfadibewegung Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module EventIndex; end

ThinkingSphinx::Index.define_partial :event do
  indexes name, number, sortable: true

  indexes groups.name, as: :group_name
end
