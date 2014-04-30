# encoding: utf-8

#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class VariousAbility < AbilityDsl::Base

  on(CustomContent) do
    permission(:admin).may(:index, :update).all
  end

  on(LabelFormat) do
    permission(:admin).may(:manage).all
  end

  if Group.course_types.present?
    on(Event::Kind) do
      permission(:admin).may(:manage).all
    end

    on(QualificationKind) do
      permission(:admin).may(:manage).all
    end
  end

end
