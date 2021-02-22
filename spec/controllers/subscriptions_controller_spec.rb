#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "spec_helper"

describe SubscriptionsController do
  before { sign_in(user) }

  let(:user) { people(:top_leader) }
  let(:group) { groups(:top_layer) }
  let(:event) { Fabricate(:event, groups: [group], dates: [Fabricate(:event_date, start_at: Time.zone.today)]) }
  let(:mailing_list) { Fabricate(:mailing_list, group: group) }

  context "GET index" do
    before do
      create_group_subscription(mailing_list)
      @person_subscription = create_person_subscription(mailing_list)
      create_event_subscription(mailing_list)
      @excluded_person_subscription = create_person_subscription(mailing_list, true)
    end

    it "groups subscriptions by type" do
      get :index, params: {group_id: group.id, mailing_list_id: mailing_list.id}

      expect(assigns(:group_subs).count).to eq 1
      expect(assigns(:person_subs).count).to eq 1
      expect(assigns(:event_subs).count).to eq 1
      expect(assigns(:excluded_person_subs).count).to eq 1
      expect(assigns(:person_add_requests)).to eq([])
    end

    it "renders csv in backround job" do
      expect {
        get :index, params: {group_id: group.id, mailing_list_id: mailing_list.id}, format: :csv
        expect(flash[:notice]).to match(/Export wird im Hintergrund gestartet und nach Fertigstellung heruntergeladen./)
        expect(response).to redirect_to(returning: true)
      }.to change(Delayed::Job, :count).by(1)
    end

    it "renders xlsx in backround job" do
      expect {
        get :index, params: {group_id: group.id, mailing_list_id: mailing_list.id}, format: :xlsx
        expect(flash[:notice]).to match(/Export wird im Hintergrund gestartet und nach Fertigstellung heruntergeladen./)
        expect(response).to redirect_to(returning: true)
      }.to change(Delayed::Job, :count).by(1)
    end

    it "sets cookie on export" do
      get :index, params: {group_id: group.id, mailing_list_id: mailing_list.id}, format: :csv

      cookie = JSON.parse(cookies[Cookies::AsyncDownload::NAME])

      expect(cookie[0]["name"]).to match(/^(subscriptions)+\S*(#{people(:top_leader).id})+$/)
      expect(cookie[0]["type"]).to match(/^csv$/)
    end

    it "exports vcf files" do
      get :index, params: {group_id: group.id, mailing_list_id: mailing_list.id}, format: :vcf
      expect(@response.media_type).to eq("text/vcard")

      cards = @response.body.split("END:VCARD\n")
      expect(cards.length).to equal(2)

      if cards[1].include?("N:Member;Bottom")
        cards.reverse!
      end

      expect(cards[0][0..23]).to eq("BEGIN:VCARD\nVERSION:3.0\n")
      expect(cards[0]).to match(/^N:Member;Bottom;;;/)
      expect(cards[0]).to match(/^FN:Bottom Member/)
      expect(cards[0]).to match(/^ADR:;;Greatstreet 345;Greattown;;3456;CH/)
      expect(cards[0]).to match(/^EMAIL;TYPE=pref:bottom_member@example.com/)

      expect(cards[1][0..23]).to eq("BEGIN:VCARD\nVERSION:3.0\n")
      expect(cards[1]).to match(/^N:#{@person_subscription.subscriber.last_name};#{@person_subscription.subscriber.first_name};;;/)
      expect(cards[1]).to match(/^FN:#{@person_subscription.subscriber.first_name} #{@person_subscription.subscriber.last_name}/)
      expect(cards[1]).to match(/^NICKNAME:#{@person_subscription.subscriber.nickname}/)
      expect(cards[1]).to match(/^EMAIL;TYPE=pref:#{@person_subscription.subscriber.email}/)
    end

    it "renders email addresses with additional ones" do
      e1 = Fabricate(:additional_email, contactable: @person_subscription.subscriber, mailings: true)
      Fabricate(:additional_email, contactable: @excluded_person_subscription.subscriber, mailings: true)
      get :index, params: {group_id: group.id, mailing_list_id: mailing_list.id}, format: :email
      expect(@response.body.split(",")).to match_array([people(:bottom_member).email, @person_subscription.subscriber.email, e1.email])
    end

    it "renders email addresses with additional_email matching preferred_labels instead of subscriber email" do
      e1 = Fabricate(:additional_email, contactable: @person_subscription.subscriber, label: :preferred)
      mailing_list.update(preferred_labels: %w[preferred])
      get :index, params: {group_id: group.id, mailing_list_id: mailing_list.id}, format: :email
      expect(@response.body.split(",")).to match_array([people(:bottom_member).email, e1.email])
    end

    it "loads pending person add requests" do
      r1 = Person::AddRequest::MailingList.create!(
        person: Fabricate(:person),
        requester: Fabricate(:person),
        body: mailing_list
      )

      get :index, params: {group_id: group.id, mailing_list_id: mailing_list.id}

      expect(assigns(:person_add_requests)).to eq([r1])
    end
  end

  def create_group_subscription(mailing_list)
    group = groups(:bottom_layer_one)
    Fabricate(:subscription,
      mailing_list: mailing_list,
      subscriber: group,
      related_role_types: [RelatedRoleType.new(role_type: Group::BottomLayer::Member.sti_name)])
  end

  def create_person_subscription(mailing_list, excluded = false)
    Fabricate(:subscription, mailing_list: mailing_list, excluded: excluded)
  end

  def create_event_subscription(mailing_list)
    Fabricate(:subscription, mailing_list: mailing_list, subscriber: event)
  end
end
