# encoding: utf-8
# frozen_string_literal: true

#  Copyright (c) 2017, Pfadibewegung Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class Export::SubscriptionsMailer < ApplicationMailer

  CONTENT_SUBSCRIPTIONS_EXPORT = 'content_subscriptions_export'.freeze

  def completed(recipient, mailing_list, export_file, export_format)
    @recipient     = recipient
    @mailing_list  = mailing_list
    @export_file   = export_file
    @export_format = export_format

    attachments["subscriptions.#{export_format}"] = export_file.read
    compose(recipient, CONTENT_SUBSCRIPTIONS_EXPORT)
  end

  private

  def placeholder_recipient_name
    @recipient.greeting_name
  end

  def placeholder_mailing_list_name
    @mailing_list.name
  end

end
