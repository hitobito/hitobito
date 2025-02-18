# frozen_string_literal: true

#  Copyright (c) 2025, Schweizer Alpen-Club. This file is part of hitobito and licensed under the
#  Affero General Public License version 3 or later. See the COPYING file at the top-level directory
#  or at https://github.com/hitobito/hitobito.

require "spec_helper"

describe Oauth::AccessTokenCleanupJob do
  let(:scopes) { "openid with_roles" }
  let(:application) { Fabricate(:application, scopes: scopes) }

  let(:user) { people(:bottom_member) }
  let(:resource_owner_id) { user.id }

  subject(:job) { described_class.new }

  let!(:token) { Fabricate(:access_token, application:, scopes:, resource_owner_id:) }

  describe "refresh token behaviour" do
    it "keeps token refreshable for 180 days" do
      travel_to(180.days.from_now) do
        expect { job.perform }.not_to change { Oauth::AccessToken.count }
      end
    end

    it "removes token after 180 days" do
      travel_to(181.days.from_now) do
        expect { job.perform }.to change { Oauth::AccessToken.count }.by(-1)
      end
    end
  end

  describe "revoked token behaviour" do
    it "keeps token revoked 2 days ago" do
      token.update!(revoked_at: 2.days.ago)
      expect { job.perform }.not_to change { Oauth::AccessToken.count }
    end

    it "removes token revoked 4 days ago" do
      token.update!(revoked_at: 4.days.ago)
      expect { job.perform }.to change { Oauth::AccessToken.count }.by(-1)
    end
  end
end
