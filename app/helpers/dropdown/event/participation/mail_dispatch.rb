# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

# rubocop:disable Rails/HelperInstanceVariable

module Dropdown::Event::Participation
  class MailDispatch < ::Dropdown::Base
    attr_reader :course, :template, :group, :participation

    delegate :t, to: :template

    def initialize(template, course, group, participation)
      @course = course
      @group = group
      @participation = participation
      @template = template
      super(template, translate(".title"), :envelope)
      init_items
    end

    private

    def init_items
      Event::Participation::MANUALLY_SENDABLE_PARTICIPANT_MAILS.each do |type|
        add_mail_item(type)
      end
    end

    def add_mail_item(mail_type)
      add_item(
        CustomContent.find_by(key: mail_type)&.label,
        template.group_event_participation_mail_dispatch_path(group, course, participation,
          mail_type: mail_type),
        method: :post,
        "data-confirm": translate(".confirmation")
      )
    end
  end
end
# rubocop:enable Rails/HelperInstanceVariable
