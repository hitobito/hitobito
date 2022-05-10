# frozen_string_literal: true

#  Copyright (c) 2012-2022, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class AsyncDownloadsController < ApplicationController

  skip_authorization_check

  def show
    if file.downloadable?(current_person)
      file_type = params[:file_type]
      Cookies::AsyncDownload.new(cookies).remove(name: params[:id], type: file_type)

      send_data file.read, filename: file.filename
    else
      render 'errors/404', status: 404
    end
  end

  def exists?
    status = file.downloadable?(current_person) ? 200 : 404

    respond_to do |format|
      format.json { render json: { status: status, progress: file.progress } }
    end
  end

  private

  def file
    @file ||= AsyncDownloadFile.from_filename(params[:id], params[:file_type])
  end

end
