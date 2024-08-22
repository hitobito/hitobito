# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of hitobito and licensed under the
#  Affero General Public License version 3 or later. See the COPYING file at the top-level directory
#  or at https://github.com/hitobito/hitobito.

class Groups::SelfInscriptionController < Wizards::BaseController
  skip_authorization_check
  skip_authorize_resource

  before_action :redirect_to_group_if_necessary

  delegate :self_registration_active?, to: :group

  private

  def wizard
    @wizard ||= model_class.new(
      group: group,
      person: person,
      current_step: params[:step].to_i,
      **model_params.to_unsafe_h
    )
  end

  def success_message
    t(".role_saved")
  end

  def model_class
    Wizards::InscribeInGroupWizard
  end

  def redirect_target
    group_person_path(person.default_group_id, person)
  end

  def redirect_with_message(message)
    redirect_to group_person_path(person.default_group_id, person), message
  end

  def redirect_to_group_if_necessary
    if self_registration_active?
      if Role.where(
        person: person,
        group: group,
        type: group.self_registration_role_type,
        archived_at: nil,
        deleted_at: nil
      ).present?

        redirect_with_message(alert: t(".role_exists"))
      end
    else
      redirect_with_message(alert: t(".disabled"))
    end
  end

  def group
    @group ||= Group.find(params[:group_id])
  end

  def person
    current_person
  end
end
