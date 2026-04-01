# frozen_string_literal: true

#  Copyright (c) 2012-2026, Puzzle ITC. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "spec_helper"

describe UserJobResultsController do
  let(:person) { people(:bottom_member) }
  let(:user_job_result) do
    create_test_user_job_result(person.id)
  end

  before do
    sign_in(person)
    user_job_result.write("Some super duper data")
  end

  context "index" do
    it "provides user job results only of current person" do
      expected_user_job_results = [user_job_result]
      unexpected_user_job_results = []
      3.times { expected_user_job_results << create_test_user_job_result(person.id) }
      3.times { unexpected_user_job_results  << create_test_user_job_result(1234) }

      get :index
      user_job_results = assigns(:user_job_results)

      expect(user_job_results).to match_array(expected_user_job_results)
      expect(user_job_results).not_to include(*unexpected_user_job_results)
    end
  end

  context "show" do
    it "allows downloading an attachment that person has access to" do
      get :download_attachment, params: {id: user_job_result.id}

      expect(response).to be_redirect
    end

    it "returns 404 if person has no access" do
      user_job_result.update!(person_id: 1234)
      get :download_attachment, params: {id: user_job_result.id}

      is_expected.to render_template("errors/404")
      expect(response.status).to match(404)
    end

    it "returns 404 if file does not exists" do
      get :download_attachment, params: {id: "unknown_file"}

      is_expected.to render_template("errors/404")
      expect(response.status).to match(404)
    end
  end

  def create_test_user_job_result(person_id)
    UserJobResult.create_default!(
      person_id, "A test job", "subscriptions_to-blorbaels-rants", "txt", false
    )
  end
end
