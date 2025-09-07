# frozen_string_literal: true

#  Copyright (c) 2025, Pfadibewegung Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito

require "rails_helper"

RSpec.describe "mailing_lists#index", type: :request do
  it_behaves_like "jsonapi authorized requests" do
    let(:params) { {} }

    subject(:make_request) do
      jsonapi_get "/api/mailing_lists", params: params
    end

    describe "basic fetch" do
      it "works" do
        expect(MailingListResource).to receive(:all).and_call_original
        make_request
        expect(response.status).to eq(200), response.body
        expect(d.map(&:jsonapi_type).uniq).to match_array(["mailing_lists"])
        expect(d.map(&:id)).to match_array(MailingList.pluck(:id))
      end
    end

    describe "requesting subscribers" do
      let(:params) { {extra_fields: {mailing_lists: "subscribers"}} }
      let!(:subscriber) do
        Fabricate(Group::TopLayer::TopAdmin.name.to_sym, group_id: groups(:top_layer).id).person
      end

      before do
        subscription = subscriptions(:leaders_group)
        subscription.related_role_types.create!(role_type: Group::TopLayer::TopAdmin.name)
      end

      it "works" do
        expect(MailingListResource).to receive(:all).and_call_original
        make_request
        expect(response.status).to eq(200), response.body
        expect(d.map(&:jsonapi_type).uniq).to match_array(["mailing_lists"])
        expect(d.map(&:id)).to match_array(MailingList.pluck(:id))
        expect(d.first.attributes["subscribers"]).to match_array([{
          list_emails: [subscriber.email],
          primary_group_id: subscriber.primary_group_id,
          primary_group_name: subscriber.primary_group.name
        }])
      end
    end
  end
end
