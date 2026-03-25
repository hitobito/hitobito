#  Copyright (c) 2012-2026, Puzzle ITC. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class UserJobResultsController < ApplicationController
  skip_authorization_check

  def index
    @user_job_results =
      UserJobResult.includes([:generated_file_attachment]).where(person_id: current_person.id)
    render "index"
  end
end
