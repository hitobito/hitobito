# encoding: utf-8

#  Copyright (c) 2012-2018, Grünliberale Partei Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.
#
class AsyncSynchronizationsController < ApplicationController
  skip_authorization_check

  def show
    if mailing_list.mailchimp_syncing
      respond_to do |format|
        if job.last_error.blank?
          format.json { render json: { status: 404 } }
        else
          AsyncSynchronizationCookie.new(cookies).remove(params[:id].to_i)
          flash[:alert] = I18n.t('layouts.synchronization.synchronization_failed',
                                 error: job.last_error.lines.first.strip)
          job.destroy
          format.json { render json: { status: 422 } }
        end
      end
    else
      AsyncSynchronizationCookie.new(cookies).remove(params[:id].to_i)
      respond_to do |format|
        format.json { render json: { status: 200 } }
      end
    end
  end

  def mailing_list
    @mailing_list ||= MailingList.find(params[:id])
  end

  def job
    @job ||= MailchimpSynchronizationJob.new(mailing_list.id).delayed_jobs.first
  end

end
