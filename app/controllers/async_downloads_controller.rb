# encoding: utf-8

#  Copyright (c) 2012-2018, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class AsyncDownloadsController < ApplicationController

  skip_authorization_check

  def show
    if file.downloadable?(current_person)
      file_type = params[:file_type]
      Cookies::AsyncDownload.new(cookies).remove(name: params[:id], type: file_type)

      data = File.read(file.full_path)
      data = css_encoding(data) if file_type == 'csv'

      send_data data, filename: filename(file_type)
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
    @file ||= AsyncDownloadFile.new(params[:id], params[:file_type])
  end

  def filename(type)
    "#{file.filename}.#{type}"
  end

  def css_encoding(data)
    data.force_encoding(Settings.csv.encoding)
  end

end
