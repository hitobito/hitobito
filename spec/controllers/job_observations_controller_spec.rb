# frozen_string_literal: true

#  Copyright (c) 2012-2026, Puzzle ITC. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "spec_helper"

describe JobObservationsController do
  let(:person) { people(:top_leader) }
  let(:other_person) { people(:bottom_member) }
  let(:job_observation) { Fabricate(:job_observation) }

  before do
    sign_in(person)
    job_observation.write("Some super duper data")
  end

  context "index" do
    it "provides job observations only of current person" do
      expected_job_observations = [job_observation]
      unexpected_job_observations = []
      3.times { expected_job_observations << Fabricate(:job_observation, person:) }
      3.times { unexpected_job_observations << Fabricate(:job_observation, person_id: other_person.id) }

      get :index
      job_observations = assigns(:job_observations)

      expect(job_observations).to eq(expected_job_observations.sort_by(&:started_at).reverse)
      expect(job_observations).not_to include(*unexpected_job_observations)
    end
  end

  context "show" do
    it "allows downloading an attachment that person has access to" do
      get :download, params: {id: job_observation.id}

      generated_file_url = rails_blob_path(
        job_observation.generated_file,
        filename: job_observation.filename_with_extension,
        disposition: "attachment"
      )
      expect(response).to redirect_to(generated_file_url)
    end

    it "returns 404 if person has no access" do
      job_observation.update!(person: other_person)
      get :download, params: {id: job_observation.id}

      is_expected.to render_template("errors/404")
      expect(response.status).to match(404)
    end

    it "returns 404 if file does not exists" do
      get :download, params: {id: "unknown_file"}

      is_expected.to render_template("errors/404")
      expect(response.status).to match(404)
    end
  end
end
