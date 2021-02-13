# encoding: utf-8

#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
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
  let(:controller)    { double().as_null_object }
  let(:participation) { event_participations(:top) }
  let(:serializer)    { EventParticipationSerializer.new(participation, controller) }

  let(:hash)          { serializer.to_hash.with_indifferent_access }

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
    expect(subject.keys).to include(*Person::PUBLIC_ATTRS.map(&:to_s))
  end

  it "includes event roles" do
    expect(subject[:roles]).to eq([{ "type" => "Event::Role::Leader", "name" => "Hauptleitung" }])
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
  end
end
