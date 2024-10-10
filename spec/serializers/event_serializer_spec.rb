# frozen_string_literal: true

#  Copyright (c) 2018, Pfadibewegung Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

# == Schema Information
#
# Table name: events
#
#  id                               :integer          not null, primary key
#  applicant_count                  :integer          default(0)
#  application_closing_at           :date
#  application_conditions           :text
#  application_opening_at           :date
#  applications_cancelable          :boolean          default(FALSE), not null
#  automatic_assignment             :boolean          default(FALSE), not null
#  cost                             :string
#  description                      :text
#  display_booking_info             :boolean          default(TRUE), not null
#  external_applications            :boolean          default(FALSE)
#  globally_visible                 :boolean
#  hidden_contact_attrs             :text
#  location                         :text
#  maximum_participants             :integer
#  minimum_participants             :integer
#  motto                            :string
#  name                             :string
#  notify_contact_on_participations :boolean          default(FALSE), not null
#  number                           :string
#  participant_count                :integer          default(0)
#  participations_visible           :boolean          default(FALSE), not null
#  priorization                     :boolean          default(FALSE), not null
#  required_contact_attrs           :text
#  requires_approval                :boolean          default(FALSE), not null
#  shared_access_token              :string
#  signature                        :boolean
#  signature_confirmation           :boolean
#  signature_confirmation_text      :string
#  state                            :string(60)
#  teamer_count                     :integer          default(0)
#  training_days                    :decimal(5, 2)
#  type                             :string
#  waiting_list                     :boolean          default(TRUE), not null
#  created_at                       :datetime
#  updated_at                       :datetime
#  application_contact_id           :integer
#  contact_id                       :integer
#  creator_id                       :integer
#  kind_id                          :integer
#  updater_id                       :integer
#
# Indexes
#
#  index_events_on_kind_id              (kind_id)
#  index_events_on_shared_access_token  (shared_access_token)
#

require "spec_helper"

describe EventSerializer do
  let(:event) { events(:top_event).decorate }
  let(:controller) { double.as_null_object }
  let(:serializer) { EventSerializer.new(event, controller: controller) }
  let(:hash) { serializer.to_hash.with_indifferent_access }

  subject { hash[:events].first }

  context "event properties" do
    it "includes all keys" do
      keys = [:name, :description, :motto, :cost, :maximum_participants, :participant_count,
        :location, :application_opening_at, :application_closing_at, :application_conditions,
        :state, :teamer_count, :external_application_link, :links, :attachments]

      keys.each do |key|
        is_expected.to have_key(key)
      end
    end

    it "includes dates properties" do
      keys = [:id, :label, :start_at, :finish_at, :location]
      keys.each do |key|
        expect(hash[:linked][:event_dates].first).to have_key(key)
      end

      expect(subject[:links]).to have_key(:dates)
    end

    it "includes groups properties" do
      keys = [:id, :href, :group_type, :layer, :name, :short_name, :email, :address,
        :zip_code, :town, :country, :created_at, :updated_at]

      group = hash[:linked][:groups].first

      keys.each do |key|
        expect(group).to have_key(key)
      end

      expect(group[:links]).to have_key(:layer_group)
      expect(group[:links]).to have_key(:hierarchies)
      expect(group[:links]).to have_key(:children)
      expect(subject[:links]).to have_key(:groups)
    end

    it "does not include kind" do
      expect(subject[:links]).not_to have_key(:kind)
    end
  end

  context "coures properties" do
    let(:event) { events(:top_course).decorate }

    it "includes kind properties" do
      keys = [:id, :label, :short_name, :minimum_age, :general_information, :application_conditions]
      keys.each do |key|
        expect(hash[:linked][:event_kinds].first).to have_key(key)
      end

      expect(subject[:links]).to have_key(:kind)
    end
  end

  context "attachments" do
    before do
      file = Tempfile.new(["foo", ".png"])
      a = event.attachments.build
      a.file.attach(io: file, filename: "foo.png")
      a.save!
    end

    it "includes attachments" do
      request = ActionController::TestRequest.create({})
      allow(controller).to receive(:request).and_return(request)
      allow(request).to receive(:host_with_port).and_return("hitobito.ch")

      is_expected.to have_key(:attachments)
      expect(subject[:attachments].count).to eq(1)
      expect(subject[:attachments][0]["file_name"]).to eq("foo.png")
      expect(subject[:attachments][0]["url"])
        .to match(/http:\/\/hitobito.ch\/rails\/active_storage\/blobs\/redirect\/.*\/foo.png/)
    end
  end
end
