# encoding: utf-8

#  Copyright (c) 2012-2019, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "spec_helper"

describe Doorkeeper::OpenidConnect::DiscoveryController do
  describe "GET#keys" do
    it "shows the keys" do
      get :keys
      expect(response.status).to eq 200
    end
  end

  describe "GET#provider" do
    it "shows the config of this oidc provider" do
      get :provider
      expect(response.status).to eq 200
    end
  end

  describe "GET#webfinger" do
    it "shows webfinger infos" do
      get :webfinger
      expect(response.status).to eq 200
    end
  end
end
