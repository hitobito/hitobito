# encoding: utf-8

#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require 'spec_helper'


describe Export::Csv::People::ParticipationsFull do

  let(:person) { people(:top_leader) }
  let(:participation) { Fabricate(:event_participation, person: person, event: events(:top_course)) }
  let(:list) { [participation] }
  let(:people_list) { Export::Csv::People::ParticipationsFull.new(list) }

  subject { people_list.attribute_labels }

  context 'additional_information' do
    before { participation.additional_information = 'asdf' }
    its([:additional_information]) { should eq 'Bemerkungen (Allgemeines, Gesundheitsinformationen, Allergien, usw.)' }
  end

  context 'questions' do
    let(:participation) { Fabricate(:event_participation, person: person, event: events(:top_course)) }
    let(:question) { events(:top_course).questions.first }

    before {  participation.init_answers }
    it 'has keys and values' do
      subject[:"question_#{event_questions(:top_ov).id}"].should eq 'GA oder Halbtax?'
      subject.keys.select { |key| key =~ /question/ }.should have(3).items
    end
  end
end
