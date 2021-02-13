#  Copyright (c) 2018, Grünliberale Partei Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "spec_helper"

describe AsyncSynchronizationsController do

  let(:person) { people(:top_leader) }
  let(:group) { groups(:top_group) }
  let(:mailing_list) { Fabricate(:mailing_list, group: group) }

  before do
    allow_any_instance_of(MailchimpSynchronizationJob)
      .to receive(:delayed_jobs).and_return([Delayed::Job.new])
    sign_in(person)
  end

  context "show" do
    it "deletes cookie and returns Status 200 if done" do
      allow(mailing_list).to receive(:mailchimp_syncing).and_return(false)

      get :show, params: { group: group, id: mailing_list }
      json = JSON.parse(response.body)

      expect(json["status"]).to match(200)
      expect(cookies[Cookies::AsyncSynchronization::NAME]).to be_nil
    end

    it "returns 404 if sync is not ready yet" do
      Cookies::AsyncSynchronization.new(cookies).set(mailing_list_id: mailing_list.id)
      mailing_list.update(mailchimp_syncing: true)
      allow_any_instance_of(Delayed::Job)
        .to receive(:last_error).and_return(nil)

      get :show, params: { group: group, id: mailing_list }
      json = JSON.parse(response.body)

      expect(json["status"]).to match(404)
      expect(cookies[Cookies::AsyncSynchronization::NAME]).to be_present
    end

    it "returns 422 if sync failed" do
      Cookies::AsyncSynchronization.new(cookies).set(mailing_list_id: mailing_list.id)
      mailing_list.update(mailchimp_syncing: true)
      allow_any_instance_of(Delayed::Job)
        .to receive(:last_error).and_return("error_message")

      get :show, params: { group: group, id: mailing_list }
      json = JSON.parse(response.body)

      expect(json["status"]).to match(422)
      expect(cookies[Cookies::AsyncSynchronization::NAME]).to be_nil
      expect(flash[:alert])
        .to eq("Beim Senden der Daten an MailChimp ist ein Fehler aufgetreten (error_message).")
    end
  end
end
