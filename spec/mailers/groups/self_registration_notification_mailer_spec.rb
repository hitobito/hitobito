# frozen_string_literal: true

#  Copyright (c) 2022, Efficiency-Club Bern. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require 'spec_helper'

describe Groups::SelfRegistrationNotificationMailer do
  let(:role) { roles(:bottom_member) }
  let(:notification_email) { 'self_registration_notification@example.com' }
  let(:mail) {  Groups::SelfRegistrationNotificationMailer.self_registration_notification(notification_email, role) }

  context 'self registration notification mail' do
    it 'shows person and group name' do
      expect(mail.subject).to eq('Benachrichtigung Selbstregistrierung')
      expect(mail.body).to include(role.group.name)
      expect(mail.body).to include(role.person.full_name)
    end
  end
end
