require "rails_helper"

RSpec.describe "mailing_lists#show", type: :request do
  it_behaves_like "jsonapi authorized requests" do
    let(:params) { {} }
    let!(:mailing_list) { mailing_lists(:leaders) }

    subject(:make_request) do
      jsonapi_get "/api/mailing_lists/#{mailing_list.id}", params: params
    end

    describe "basic fetch" do
      it "works" do
        expect(MailingListResource).to receive(:find).and_call_original
        make_request
        expect(response.status).to eq(200)
        expect(d.jsonapi_type).to eq("mailing_lists")
        expect(d.id).to eq(mailing_list.id)
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
        expect(MailingListResource).to receive(:find).and_call_original
        make_request
        expect(response.status).to eq(200)
        expect(d.jsonapi_type).to eq("mailing_lists")
        expect(d.id).to eq(mailing_list.id)
        expect(d.attributes["subscribers"]).to match_array([{
          list_emails: [subscriber.email],
          primary_group_id: subscriber.primary_group_id,
          primary_group_name: subscriber.primary_group.name
        }])
      end
    end
  end
end
