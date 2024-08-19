#  Copyright (c) 2024, SAC CAS. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class Wizards::InscribeInGroupWizard < Wizards::Base
  self.steps = [Wizards::Steps::ConfirmInscription]

  attr_reader :group
  attr_reader :role

  def initialize(group:, person:, current_step: 0, **params)
    super(current_step: current_step, **params)
    raise "Self-registration is not enabled for this group." if group.self_registration_role_type.nil?
    @group = group
    @person = person
    @role = build_role
  end

  def save!
    ::Person.transaction do
      super
      role.save!
      send_notification_email
    end
  end

  private

  def build_role
    @group.self_registration_role_type.constantize.new(group: @group, person: @person)
  end

  def send_notification_email
    return if group.self_registration_notification_email.blank?

    Groups::SelfRegistrationNotificationMailer
      .self_registration_notification(group.self_registration_notification_email,
        @role).deliver_later
  end
end
