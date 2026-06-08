# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

# rubocop:disable Rails/HelperInstanceVariable

module Dropdown::Event::Participation
  class SendMail < ::Dropdown::Base
    attr_reader :event, :template, :group, :participation

    delegate :t, to: :template

    def initialize(template, event, group, participation)
      @event = event
      @group = group
      @participation = participation
      @template = template
      super(template, translate(".title"), :envelope)
      init_items
    end

    private

    def init_items
      custom_contents.each do |custom_content|
        add_mail_item(custom_content)
      end
    end

    def custom_contents
      @custom_contents ||= CustomContent
        .in_context([group.layer_group, nil])
        .where(key: custom_content_keys)
        .includes(:translations)
        .sort_by { |c| custom_content_keys.index(c.key) }
    end

    def custom_content_keys
      @custom_content_keys ||= participation.manually_sendable_mails
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
      template.group_event_participation_send_mail_path(
        group,
        event,
        participation,
        mail_type:
      )
    end
  end
end
# rubocop:enable Rails/HelperInstanceVariable
