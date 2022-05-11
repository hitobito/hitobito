# frozen_string_literal: true

#  Copyright (c) 2012-2022, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class AsyncDownloadsController < ApplicationController

  skip_authorization_check

  def show
    if file.downloadable?(current_person)
      Cookies::AsyncDownload.new(cookies).remove(name: params[:id], type: params[:file_type])

      redirect_to rails_blob_path(
        file.generated_file,
        filename: file.filename,
        disposition: 'attachment'
      )
    else
      render 'errors/404', status: :not_found
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
