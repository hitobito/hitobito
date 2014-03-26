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

  context 'integration' do

    let(:data) { Export::Csv::People::ParticipationsFull.export(list) }
    let(:csv) { CSV.parse(data, headers: true, col_sep: Settings.csv.separator) }
    let(:full_headers) do
      ['Vorname', 'Nachname', 'Firmenname', 'Übername', 'Firma', 'Haupt-E-Mail',
       'Adresse', 'PLZ', 'Ort', 'Land', 'Geschlecht', 'Geburtstag',
       'Bemerkungen (Allgemeines, Gesundheitsinformationen, Allergien, usw.)', 'Rollen']
    end

    subject { csv }

    its(:headers) { should == full_headers }

    context 'first row' do
      subject { csv[0] }

      its(['Vorname']) { should eq person.first_name }
      its(['Rollen']) { should be_blank }

      context 'with additional information' do
        before { participation.update_attribute(:additional_information, 'foobar') }
        its(['Bemerkungen (Allgemeines, Gesundheitsinformationen, Allergien, usw.)']) { should eq 'foobar' }
      end

      context 'with roles' do
        before do
          Fabricate(:event_role, participation: participation, type: 'Event::Role::Leader')
          Fabricate(:event_role, participation: participation, type: 'Event::Role::AssistantLeader')
        end
        its(['Rollen']) { should eq 'Hauptleitung, Leitung' }
      end

      context 'with answers' do
        let(:first_question) { event_questions(:top_ov) }
        let(:first_answer)  { participation.answers.find_by_question_id(first_question.id) }

        let(:second_question) { event_questions(:top_vegi) }
        let(:second_answer)  { participation.answers.find_by_question_id(second_question.id) }

        before do
          participation.init_answers
          first_answer.update_attribute(:answer, first_question.choice_items.first)
          second_answer.update_attribute(:answer, second_question.choice_items.first)
          participation.reload
        end

        it 'has answer for first question' do
          subject["#{first_question.question}"].should eq 'GA'
          subject["#{second_question.question}"].should eq 'ja'
        end
      end
    end
  end
end
