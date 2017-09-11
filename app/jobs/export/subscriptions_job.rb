# encoding: utf-8
# frozen_string_literal: true

#  Copyright (c) 2017, Pfadibewegung Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class Export::SubscriptionsJob < BaseJob

  self.parameters = [:format, :mailing_list_id, :user_id, :locale]

  def initialize(format, mailing_list_id, user_id)
    super()
    @format = format
    @mailing_list_id = mailing_list_id
    @user_id = user_id
  end

  def perform
    set_locale
    Export::SubscriptionsMailer.completed(recipient, mailing_list, export_file, @format).deliver_now
  ensure
    export_file.close
    export_file.unlink
  end

  def recipient
    @recipient ||= Person.find(@user_id)
  end

  def export_file
    @export_file ||= begin
                       file = Tempfile.new("subscriptions-#{@mailing_list_id}-#{@format}-export")
                       file << data
                       file.rewind
                       file
                     end
  end

  def mailing_list
    @mailing_list ||= MailingList.find(@mailing_list_id)
  end

  def data
    Export::Tabular::People::PeopleAddress.export(
      @format,
      mailing_list.people
                  .order_by_name
                  .preload_public_accounts
                  .includes(roles: :group)
    )
  end

end
