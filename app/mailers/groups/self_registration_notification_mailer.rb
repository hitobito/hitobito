# frozen_string_literal: true

#  Copyright (c) 2022, Efficiency-Club Bern. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class Groups::SelfRegistrationNotificationMailer < ApplicationMailer

  CONTENT_SELF_REGISTRATION_NOTIFICATION = 'self_registration_notification'.freeze

  def self_registration_notification(notification_email, role)
    @role = role

    compose(notification_email, CONTENT_SELF_REGISTRATION_NOTIFICATION)
  end

  private

  def placeholder_group_name
    @role.group.name
  end

  def placeholder_person_name
    @role.person.full_name
  end

  def placeholder_person_url
    link_to(group_person_url(@role.group, @role.person))
  end
end
