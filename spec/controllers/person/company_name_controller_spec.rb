# encoding: utf-8

#  Copyright (c) 2017, Dachverband Schweizer Jugendparlamente. This file is
#  part of hitobito and licensed under the Affero General Public License
#  version 3 or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "spec_helper"

describe Person::CompanyNameController do
  let(:top_leader) { people(:top_leader) }

  before { sign_in(top_leader) }

  context "GET index" do
    it "queries company-names" do
      Fabricate(:person, company_name: "Puzzle ITC")
      Fabricate(:person, company_name: "PuzzleWorks Ltd")
      Fabricate(:person, company_name: "Swisscom")
      get :index, params: {q: "puz"}

      expect(response.body).to match(/Puzzle ITC/)
      expect(response.body).to match(/PuzzleWorks Ltd/)
    end
  end
end
