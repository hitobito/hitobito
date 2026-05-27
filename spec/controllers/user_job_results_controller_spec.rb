# frozen_string_literal: true

#  Copyright (c) 2012-2026, Puzzle ITC. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "spec_helper"

describe UserJobResultsController do
  let(:person) { people(:top_leader) }
  let(:other_person) { people(:bottom_member) }
  let(:user_job_result) { Fabricate(:user_job_result) }

  before do
    sign_in(person)
    user_job_result.write("Some super duper data")
  end

  context "index" do
    it "provides user job results only of current person" do
      expected_user_job_results = [user_job_result]
      unexpected_user_job_results = []
      3.times { expected_user_job_results << Fabricate(:user_job_result, person:) }
      3.times { unexpected_user_job_results << Fabricate(:user_job_result, person_id: other_person.id) }

      get :index
      user_job_results = assigns(:user_job_results)

      expect(user_job_results).to eq(expected_user_job_results.sort_by(&:start_timestamp).reverse)
      expect(user_job_results).not_to include(*unexpected_user_job_results)
    end
  end

  context "show" do
    it "allows downloading an attachment that person has access to" do
      get :download, params: {id: user_job_result.id}

      expect(response).to be_redirect
    end

    it "returns 404 if person has no access" do
      user_job_result.update!(person: other_person)
      get :download, params: {id: user_job_result.id}

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
