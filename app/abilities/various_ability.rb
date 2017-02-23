# encoding: utf-8

#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class VariousAbility < AbilityDsl::Base

  on(CustomContent) do
    class_side(:index).if_admin
    permission(:admin).may(:update).all
  end

  on(LabelFormat) do
    class_side(:index).everybody
    class_side(:manage_global).if_admin
    permission(:admin).may(:manage).all
    permission(:any).may(:create, :update, :destroy, :read).own
    permission(:any).may(:create, :new).all
  end

  if Group.course_types.present?
    on(Event::Kind) do
      class_side(:index).if_admin
      permission(:admin).may(:manage).all
    end

    on(QualificationKind) do
      class_side(:index).if_admin
      permission(:admin).may(:manage).all
    end
  end

  def own
    subject.user_id == user.id
  end
end
