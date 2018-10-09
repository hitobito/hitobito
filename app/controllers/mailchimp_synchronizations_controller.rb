# encoding: utf-8

#  Copyright (c) 2012-2018, Grünliberale Partei Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class MailchimpSynchronizationsController < ApplicationController

  def create
    mailing_list = MailingList.find(params[:mailing_list_id])

    authorize!(:update, mailing_list)

    AsyncSynchronizationCookie.new(cookies).set(mailing_list.id)
    MailchimpSynchronizationJob.new(mailing_list.id).enqueue!

    redirect_to(action: :index, controller: :subscriptions)
  end

end
