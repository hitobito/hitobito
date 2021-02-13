# encoding: utf-8

#  Copyright (c) 2018, Grünliberale Partei Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class AsyncSynchronizationsController < ApplicationController
  skip_authorization_check

  respond_to :json

  def show
    if mailing_list.mailchimp_syncing
      return synchronization_failed if job.last_error.present?
      render json: {status: 404}
    else
      Cookies::AsyncSynchronization.new(cookies).remove(mailing_list_id: params[:id].to_i)
      render json: {status: 200}
    end
  end

  private

  def synchronization_failed
    Cookies::AsyncSynchronization.new(cookies).remove(mailing_list_id: params[:id].to_i)
    flash[:alert] = I18n.t("layouts.synchronization.synchronization_failed",
      error: job.last_error.lines.first.strip)
    job.destroy
    render json: {status: 422}
  end

  def mailing_list
    @mailing_list ||= MailingList.find(params[:id])
  end

  def job
    @job ||= MailchimpSynchronizationJob.new(mailing_list.id).delayed_jobs.first
  end
end
