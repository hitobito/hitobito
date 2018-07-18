# encoding: utf-8

#  Copyright (c) 2012-2018, Grünliberale Partei Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class MailchimpSynchronizationsController < ApplicationController
  include Concerns::AsyncSynchronization

  def create
    mailing_list = MailingList.find(params[:mailing_list_id])

    authorize!(:update, mailing_list)

    #TODO How to pass the job id to the cookie setter?
    with_async_synchronization_cookie(job_id) do
      MailchimpSynchronizationJob.new(mailing_list.id).enqueue!
    end

    redirect_to(action: :index, controller: :subscriptions)
  end

end
