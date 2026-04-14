#  Copyright (c) 2012-2026, Puzzle ITC. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class UserJobResultsController < ApplicationController
  skip_authorization_check

  def index
    @user_job_results =
      UserJobResult.includes([:generated_file_attachment])
        .where(person_id: current_person.id)
        .order(start_timestamp: :desc)
        .page(params[:page])

    render "index"
  end

  def download_attachment
    user_job_result = UserJobResult.find_by(id: params[:id])
    if user_job_result&.downloadable?(current_person)
      redirect_to rails_blob_path(
        user_job_result.generated_file,
        filename: user_job_result.filename,
        disposition: "attachment"
      )
    else
      render "errors/404", status: :not_found
    end
  end
end
