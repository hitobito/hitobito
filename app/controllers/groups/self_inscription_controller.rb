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
    @role.person = current_person
    @role.save
    send_notification_email
    redirect_to_group
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

  def set_success_notice
    flash[:notice] = I18n.t('devise.registrations.signed_up') #TODO eingeschrieben, nicht registriert
  end

  def redirect_to_group
    redirect_to group_path(group)
  end

  def redirect_to_group_if_necessary
    
    binding.pry
    #TODO: check if role already available
    return redirect_to_group unless self_registration_active?
  end

  # def signed_in?
  #   current_user.present?
  # end

  # def valid?
  #   entry.valid? && person.valid?
  # end

  def group
    @group ||= Group.find(params[:group_id])
  end

  # def person
  #   @person ||= current_person #entry.person
  # end

  def path_args(entry)
    [group, entry]
  end

  def self.model_class
    @model_class ||= Role
  end
end
