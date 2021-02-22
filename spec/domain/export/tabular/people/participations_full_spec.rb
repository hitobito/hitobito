#  Copyright (c) 2012-2017, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "spec_helper"

describe Export::Tabular::People::ParticipationsFull do
  let(:person) { people(:top_leader) }
  let(:participation) { Fabricate(:event_participation, person: person, event: events(:top_course)) }
  let(:list) { [participation] }
  let(:people_list) { Export::Tabular::People::ParticipationsFull.new(list) }

  subject { people_list.attribute_labels }

  context "additional_information" do
    its([:additional_information]) { is_expected.to eq "Zusätzliche Angaben" }
  end

  context "participation_additional_information" do
    its([:participation_additional_information]) { is_expected.to eq "Bemerkungen" }
  end

  context "questions" do
    let(:participation) { Fabricate(:event_participation, person: person, event: events(:top_course)) }
    let(:question) { events(:top_course).questions.first }

    before { participation.init_answers }

    it "has keys and values" do
      expect(subject[:"question_#{event_questions(:top_ov).id}"]).to eq "GA oder Halbtax?"
      expect(subject.keys.count { |key| key =~ /question/ }).to eq(3)
    end
  end
end
