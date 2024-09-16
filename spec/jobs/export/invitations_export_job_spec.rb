#  Copyright (c) 2017-2022, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "spec_helper"

describe Export::InvitationsExportJob do
  subject { Export::InvitationsExportJob.new(format, user.id, course.id, filename: filename) }

  let(:filename) { AsyncDownloadFile.create_name("invitations_export", user.id) }
  let(:file) { AsyncDownloadFile.from_filename(filename, format) }

  let(:user) { people(:top_leader) }
  let(:group) { groups(:top_group) }
  let!(:person1) { Fabricate(Group::TopGroup::Member.name.to_sym, group: group).person }

  let(:course) do
    course = Fabricate(:course, groups: [group])
    course.dates << Fabricate(:event_date, event: course, start_at: course.dates.first.start_at)
    course
  end

  let(:ability) do
    Ability.new(:user)
  end

  before do
    Event::Invitation.create!(event: course, person: user, participation_type: Event::Role::Leader)
    Event::Invitation.create!(event: course, person: person1, participation_type: Event::Role::Participant)
  end

  context "creates a CSV-Export" do
    let(:format) { :csv }

    it "and saves it" do
      subject.perform

      lines = file.read.lines
      expect(lines.size).to eq(3)
    end
  end

end
