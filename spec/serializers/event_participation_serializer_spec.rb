# frozen_string_literal: true

#  Copyright (c) 2012-2026, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

# == Schema Information
#
# Table name: event_participations
#
#  id                     :integer          not null, primary key
#  event_id               :integer          not null
#  person_id              :integer          not null
#  additional_information :text(65535)
#  created_at             :datetime
#  updated_at             :datetime
#  active                 :boolean          default(FALSE), not null
#  application_id         :integer
#  qualified              :boolean

require "spec_helper"

describe EventParticipationSerializer do
  let(:viewer) { people(:top_leader) }
  let(:controller) { double(current_ability: Ability.new(viewer)).as_null_object }
  let(:participation) { event_participations(:top) }
  let(:serializer) { EventParticipationSerializer.new(participation, controller:) }

  let(:hash) { serializer.to_hash.with_indifferent_access }

  subject { hash[:event_participations].first }

  it "includes json_api properties" do
    expect(subject[:id]).to eq participation.id.to_s
    expect(subject[:type]).to eq "event_participations"
  end

  it "includes main event_participation attributes" do
    expect(subject).to have_key(:additional_information)
    expect(subject).to have_key(:qualified)
    expect(subject[:active]).to eq true
  end

  it "includes main person attributes " do
    participation.person.update(nickname: "Nick", birthday: Date.new(2000, 12, 31), gender: "m")

    expect(subject[:first_name]).to eq("Bottom")
    expect(subject[:last_name]).to eq("Member")
    expect(subject[:email]).to eq("bottom_member@example.com")
    expect(subject[:nickname]).to eq("Nick")
    expect(subject[:birthday]).to eq("2000-12-31")
    expect(subject[:gender]).to eq("m")
    expect(subject.keys).to include(*(Person::PUBLIC_ATTRS - [:picture]).map(&:to_s))
  end

  it "includes event roles" do
    expect(subject[:roles]).to eq([{
      "type" => "Event::Role::Leader",
      "role_class" => "Event::Role::Leader",
      "name" => "Hauptleitung"
    }])
  end

  describe "additional information" do
    before { participation.update!(additional_information: "Allergisch auf Nüsse") }

    it "is included for a viewer with show_details" do
      expect(subject[:additional_information]).to eq "Allergisch auf Nüsse"
    end

    context "for a viewer without show_details" do
      let(:viewer) do
        treasurer_participation = Fabricate(:event_participation, event: participation.event)
        Fabricate(Event::Role::Treasurer.sti_name, participation: treasurer_participation)
        treasurer_participation.person
      end

      it "is omitted" do
        expect(subject).not_to have_key(:additional_information)
      end
    end

    context "for a service token without the event_participations scope" do
      let(:token) do
        Fabricate(:service_token, layer: groups(:top_layer), permission: :layer_and_below_full,
          events: true, event_participations: false)
      end
      let(:controller) { double(current_ability: TokenAbility.new(token)).as_null_object }

      it "is included" do
        expect(subject[:additional_information]).to eq "Allergisch auf Nüsse"
      end
    end
  end

  it "includes person template link" do
    expect(hash["links"]["event_participations.person"]).to have_key("href")
  end

  context "answers" do
    before do
      participation.answers.create!(question: event_questions(:top_ov), answer: "GA")
      participation.answers.create!(question: event_questions(:top_vegi), answer: "ja")
    end

    it "includes ids in invoice" do
      expect(subject[:links][:event_answers]).to have(2).items
    end

    it "invoices keys in links" do
      keys = [:question, :answer]
      keys.each do |key|
        expect(hash[:linked][:event_answers].first).to have_key(key)
      end
    end

    context "for a viewer with a role selected on only one question" do
      let(:viewer) do
        cook_participation = Fabricate(:event_participation, event: participation.event)
        Fabricate(Event::Role::Cook.sti_name, participation: cook_participation)
        cook_participation.person
      end

      before { event_questions(:top_ov).update!(visible_role_types: [Event::Role::Cook.sti_name]) }

      it "includes only the answer of that question" do
        expect(hash[:linked][:event_answers].pluck(:answer)).to eq ["GA"]
      end
    end
  end
end
