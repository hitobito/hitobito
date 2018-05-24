# encoding: utf-8
# frozen_string_literal: true

#  Copyright (c) 2017, Pfadibewegung Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class Export::EventParticipationsExportMailer < ApplicationMailer

  CONTENT_EVENT_PARTICIPATIONS_EXPORT = 'content_event_participations_export'.freeze

  def completed(recipient, export_file, export_format)
    @recipient     = recipient
    @export_file   = export_file
    @export_format = export_format

    attachments["event_participations_export.#{export_format}"] = export_file.read
    compose(recipient, CONTENT_EVENT_PARTICIPATIONS_EXPORT)
  end

  private

  def placeholder_recipient_name
    @recipient.greeting_name
  end
end
