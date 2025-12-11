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
      load_custom_contents.each do |custom_content|
        add_mail_item(custom_content)
      end
    end

    def load_custom_contents
      keys = custom_content_keys
      CustomContent.where(key: keys).includes(:translations).sort_by { |c| keys.index(c.key) }
    end

    def custom_content_keys
      Event::Participation::MANUALLY_SENDABLE_PARTICIPANT_MAILS
    end

    def add_mail_item(custom_content)
      add_item(
        custom_content.label,
        mail_dispatch_path(custom_content.key),
        method: :post,
        "data-confirm": translate(".confirmation")
      )
    end

    def mail_dispatch_path(mail_type)
      template.group_event_participation_mail_dispatch_path(
        group,
        course,
        participation,
        mail_type:
      )
    end
  end
end
# rubocop:enable Rails/HelperInstanceVariable
