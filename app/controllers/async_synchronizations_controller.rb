# encoding: utf-8

#  Copyright (c) 2012-2018, Grünliberale Partei Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.
#
class AsyncSynchronizationsController < ApplicationController
  skip_authorization_check

  def show
    if MailingList.find(params[:id]).syncing_mailchimp
      respond_to do |format|
        format.json { render json: { status: 404 } }
      end
    else
      AsyncSynchronizationCookie.new(cookies).remove(params[:id].to_i)
      respond_to do |format|
        format.json { render json: { status: 200 } }
      end
    end
  end


end
