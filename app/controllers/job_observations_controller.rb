#  Copyright (c) 2012-2026, Puzzle ITC. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class JobObservationsController < ApplicationController
  skip_authorization_check

  decorates :job_observations

  def index
    @job_observations = current_person.job_observations
      .includes([:generated_file_attachment])
      .order(started_at: :desc)
      .page(params[:page])

    render "index"
  end

  def download
    job_observation = JobObservation.find_by(id: params[:id])
    if job_observation&.downloadable?(current_person)
      redirect_to rails_blob_path(
        job_observation.generated_file,
        filename: job_observation.filename,
        disposition: "attachment"
      )
    else
      render "errors/404", status: :not_found
    end
  end
end
