# frozen_string_literal: true

#  Copyright (c) 2021, Katholische Landjugendbewegung Paderborn. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class FamilyMember < ApplicationRecord
  include I18nEnums

  i18n_enum :kind, %w(sibling).freeze # could be: parent child sibling
end
