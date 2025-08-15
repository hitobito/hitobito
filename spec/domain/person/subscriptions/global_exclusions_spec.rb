# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "spec_helper"

describe Person::Subscriptions::GlobalExclusions do
  let(:leaders) { mailing_lists(:leaders) }
  let(:members) { mailing_lists(:members) }
  let(:person) { people(:top_leader) }

  subject(:exclusions) { described_class.new(person.id).excluding_mailing_list_ids }

  it "is empty when no globally excluding lists exist" do
    expect(exclusions).to be_empty
  end

  it "is empty if person is included by language" do
    person.update(language: :fr)
    leaders.update(filter_chain: {language: {allowed_values: :fr}})
    expect(exclusions).to be_empty
  end

  it "is empty if person is included by language and gender" do
    person.update(language: :fr, gender: :w)
    leaders.update(filter_chain: {attributes: {"123": {key: "gender", constraint: "equal", value: "w"}},
                                  language: {allowed_values: :fr}})
    expect(exclusions).to be_empty
  end

  it "includes leaders if person is excluded by language" do
    leaders.update(filter_chain: {language: {allowed_values: :fr}})
    expect(exclusions).to eq [leaders]
  end

  it "includes leaders if person is included by language but excluded by gender" do
    person.update(language: :fr, gender: :m)
    leaders.update(filter_chain: {attributes: {"123": {key: "gender", constraint: "equal", value: "w"}},
                                  language: {allowed_values: :fr}})
    expect(exclusions).to eq [leaders]
  end

  it "includes both excluding lists" do
    members.update(filter_chain: {language: {allowed_values: :fr}})
    leaders.update(filter_chain: {attributes: {"123": {key: "gender", constraint: "equal", value: "w"}}})
    expect(exclusions).to match_array [leaders, members]
  end
end
