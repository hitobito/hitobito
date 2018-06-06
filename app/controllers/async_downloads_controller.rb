# encoding: utf-8

#  Copyright (c) 2012-2018, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class AsyncDownloadsController < ApplicationController

  skip_before_action :authenticate_person!
  skip_authorization_check

  def show
    if async_download_file.downloadable?(current_person)
      AsyncDownloadCookie.new(cookies, params[:id]).remove
      send_file async_download_file.full_path, x_sendfile: true
    else
      render 'errors/404', status: 404
    end
  end

  def exists?
    status = async_download_file.downloadable?(current_person) ? 200 : 404

    respond_to do |format|
      format.json { render json: { status: status } }
    end
  end

  private

  def async_download_file
    AsyncDownloadFile.new(params[:id], params[:file_type])
  end

end
