# frozen_string_literal: true

# Copyright (c) 2012-2021, Hitobito AG. This file is part of
# hitobito and licensed under the Affero General Public License version 3
# or later. See the COPYING file at the top-level directory or at
# https://github.com/hitobito/hitobito.

class MailingLists::BulkMail::ForwardBounceMailJob < BaseJob

  self.parameters = [:message]

  def initialize(message)
    super()
    @message = message
  end

  def perform
    # forward_mail()
  end

  private

  def forward_mail(mail)
    if defined?(ActionMailer::Base)
      ActionMailer::Base.wrap_delivery_behavior(mail)
    end

    # set Return-Path as recommended in: https://stackoverflow.com/a/154794
    mail.header['Return-Path'] = '<>'
    mail.deliver
  end

end

