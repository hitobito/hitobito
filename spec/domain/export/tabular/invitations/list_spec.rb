# frozen_string_literal: true

#  Copyright (c) 2024, Cevi Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "spec_helper"
require "csv"

describe Export::Tabular::Invitations::List do
  let(:group) { groups(:top_group) }
  let!(:person1) { Fabricate(Group::TopGroup::Member.name.to_sym, group: group).person }
  let!(:person2) { Fabricate(Group::TopGroup::Member.name.to_sym, group: group).person }

  let(:course) do
    course = Fabricate(:course, groups: [group])
    course.dates << Fabricate(:event_date, event: course, start_at: course.dates.first.start_at)
    course
  end

  let(:ability) do
    Ability.new(people(:top_leader))
  end

  before do
    Event::Invitation.create!(event: course, person: person1, participation_type: Event::Role::Leader)
    Event::Invitation.create!(event: course, person: person2, participation_type: Event::Role::Participant)
  end

  let(:data) { Export::Tabular::Invitations::List.csv(course.invitations, ability) }
  let(:data_without_bom) { data.gsub(Regexp.new("^#{Export::Csv::UTF8_BOM}"), "") }
  let(:csv) { CSV.parse(data_without_bom, headers: true, col_sep: Settings.csv.separator) }

  subject { csv }

  its(:headers) do
    expected = [
      "Person",
      "Mail",
      "Teilnahmerolle",
      "Status",
      "Ablehnungsdatum",
      "Erstellungsdatum"
    ]

    is_expected.to match_array expected
    is_expected.to eq expected
  end

  it "has 2 items" do
    expect(subject.size).to eq(2)
  end

  context "first row, as leader" do
    let(:contact) { person1 }

    subject { csv[0] }

    its(["Person"]) { is_expected.to eq contact.to_s }
    its(["Mail"]) { is_expected.to eq contact.email }
    its(["Teilnahmerolle"]) { is_expected.to eq Event::Role::Leader.model_name.human }
    its(["Status"]) { is_expected.to eq "Eingeladen" }
    its(["Ablehnungsdatum"]) { is_expected.to be_nil }
    its(["Erstellungsdatum"]) { is_expected.to eq Time.zone.now.strftime("%d.%m.%Y %H:%M") }
  end

  context "second row as participant" do
    let(:contact) { person2 }

    subject { csv[1] }

    its(["Person"]) { is_expected.to eq contact.to_s }
    its(["Mail"]) { is_expected.to eq contact.email }
    its(["Teilnahmerolle"]) { is_expected.to eq Event::Role::Participant.model_name.human }
    its(["Status"]) { is_expected.to eq "Eingeladen" }
    its(["Ablehnungsdatum"]) { is_expected.to be_nil }
    its(["Erstellungsdatum"]) { is_expected.to eq Time.zone.now.strftime("%d.%m.%Y %H:%M") }
  end
end
