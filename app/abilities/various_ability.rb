# frozen_string_literal: true

#  Copyright (c) 2012-2021, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class VariousAbility < AbilityDsl::Base

  on(CustomContent) do
    class_side(:index).if_admin
    permission(:admin).may(:update).all
  end

  on(HelpText) do
    class_side(:index).if_admin
    permission(:admin).may(:manage).all
  end

  on(HitobitoLogEntry) do
    permission(:admin).may(:manage).all
  end

  on(LabelFormat) do
    class_side(:index).everybody_unless_only_basic_permissions_roles
    class_side(:manage_global).if_admin
    permission(:admin).may(:manage).all
    permission(:any).may(:create, :update, :destroy, :show).own_unless_only_basic_permissions_roles
  end

  on(Event::Kind) do
    class_side(:index).if_admin_and_course_types_present
    permission(:admin).may(:manage).if_course_types_present
  end

  on(QualificationKind) do
    class_side(:index).if_admin_and_course_types_present
    permission(:admin).may(:manage).if_course_types_present
  end

  on(Event::KindCategory) do
    class_side(:index).if_admin_and_course_types_present
    permission(:admin).may(:manage).if_course_types_present
  end

  def own_unless_only_basic_permissions_roles
    return false if user.roles.all?(&:basic_permissions_only)

    subject.person_id == user.id
  end

  def everybody_unless_only_basic_permissions_roles
    !user.roles.all?(&:basic_permissions_only)
  end

  def if_admin_and_course_types_present
    if_admin && if_course_types_present
  end

  def if_course_types_present
    Group.course_types.present?
  end
end
