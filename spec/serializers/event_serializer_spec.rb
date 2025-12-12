# frozen_string_literal: true

#  Copyright (c) 2018, Pfadibewegung Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.
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
