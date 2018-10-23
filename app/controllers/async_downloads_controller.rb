# encoding: utf-8

#  Copyright (c) 2012-2018, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class AsyncDownloadsController < ApplicationController

  skip_authorization_check

  def show
    if async_download_file.downloadable?(current_person)
      file_type = params[:file_type]
      AsyncDownloadCookie.new(cookies).remove(params[:id], file_type)

      data = File.read(async_download_file.full_path)
      data = css_encoding(data) if file_type == 'csv'

      send_data data, filename: filename(file_type)
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

  def filename(type)
    "#{async_download_file.filename}.#{type}"
  end

  def css_encoding(data)
    data.force_encoding(Settings.csv.encoding)
  end

end
