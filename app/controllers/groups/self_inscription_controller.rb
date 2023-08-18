# frozen_string_literal: true

#  Copyright (c) 2023, Pfadibewegung Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class Groups::SelfInscriptionController < CrudController

  skip_authorization_check
  skip_authorize_resource

  before_action :redirect_to_group_if_necessary

  delegate :self_registration_active?, to: :group

  def create
    @role = build_entry
    @role.group = group
    @role.type = group.self_registration_role_type
    @role.person = person
    @role.save
    send_notification_email
    redirect_with_message(notice: t('.role_saved'))
  end

  private

  def send_notification_email   
    return if group.self_registration_notification_email.blank?

    Groups::SelfRegistrationNotificationMailer
      .self_registration_notification(group.self_registration_notification_email,
                                      @role).deliver_now
  end

  def return_path
    super.presence || group_path(group, format: request.format.to_sym)
  end

  def redirect_with_message(message)
    return redirect_to group_person_path(person.default_group_id, person), message
  end

  def redirect_to_group_if_necessary
    if Role.where(person: person, group: group, type: group.self_registration_role_type).present?
      return redirect_with_message(alert: t('.role_exists'))
    end

    return redirect_with_message(alert: t('.disabled')) unless self_registration_active?
  end

  def group
    @group ||= Group.find(params[:group_id])
  end

  def person
    current_person
  end

  def path_args(entry)
    [group, entry]
  end

  def self.model_class
    @model_class ||= Role
  end
end
