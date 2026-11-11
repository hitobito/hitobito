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
    it "keeps token refreshable for 7 days" do
      travel_to(7.days.from_now.noon) do
        expect { job.perform }.not_to change { Oauth::AccessToken.count }
      end
    end

    it "removes token after 7 days" do
      travel_to(181.days.from_now.noon) do
        expect { job.perform }.to change { Oauth::AccessToken.count }.by(-1)
      end
    end

    context "with refresh token lifetime on application" do
      before { application.update!(refresh_token_lifetime_days: 180) }

      it "keeps token refreshable for the configured lifetime" do
        travel_to(179.days.from_now.noon) do
          expect { job.perform }.not_to change { Oauth::AccessToken.count }
        end
      end

      it "removes token after the configured lifetime" do
        travel_to(181.days.from_now.noon) do
          expect { job.perform }.to change { Oauth::AccessToken.count }.by(-1)
        end
      end

      it "keeps applying the default lifetime to other applications" do
        other_token = Fabricate(:access_token, application: Fabricate(:application, scopes:),
          scopes:, resource_owner_id:)

        travel_to(9.days.from_now.noon) do
          job.perform
        end

        expect(Oauth::AccessToken.all).to eq [token]
        expect { other_token.reload }.to raise_error(ActiveRecord::RecordNotFound)
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
