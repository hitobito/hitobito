# encoding: utf-8

#  Copyright (c) 2012-2017, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require 'spec_helper'
require 'csv'

describe Export::Tabular::People::ParticipationsFull do

  let(:person) { people(:top_leader) }
  let(:participation) { Fabricate(:event_participation, person: person, event: events(:top_course)) }
  let(:list) { [participation] }
  let(:people_list) { Export::Tabular::People::ParticipationsFull.new(list) }

  subject { people_list.attribute_labels }

  context 'additional_information' do
    its([:additional_information]) { should eq 'Zusätzliche Angaben' }
  end

  context 'participation_additional_information' do
    its([:participation_additional_information]) { should eq 'Bemerkungen' }
  end

  context 'questions' do
    let(:participation) { Fabricate(:event_participation, person: person, event: events(:top_course)) }

    it 'has keys and values of application questions' do
      participation.init_answers
      expect(subject[:"question_#{event_questions(:top_ov).id}"]).to eq 'GA oder Halbtax?'
      expect(subject.keys.select { |key| key =~ /question/ }.size).to eq(3)
    end

    it 'has keys and values of admin questions' do
      irgendwas = events(:top_course).questions.create!(question: 'Irgendwas', admin: true)
      participation.init_answers
      expect(subject[:"question_#{irgendwas.id}"]).to eq 'Irgendwas'
      expect(subject.keys.select { |key| key =~ /question/ }.size).to eq(4)
    end
  end

  context 'integration' do

    let(:data) { Export::Tabular::People::ParticipationsFull.export(:csv, list) }
    let(:csv) { CSV.parse(data, headers: true, col_sep: Settings.csv.separator) }
    let(:full_headers) do
      ['Vorname', 'Nachname', 'Firmenname', 'Übername', 'Firma', 'Haupt-E-Mail',
       'Adresse', 'PLZ', 'Ort', 'Land', 'Geschlecht', 'Geburtstag',
       'Zusätzliche Angaben', 'Rollen', 'Anmeldedatum', 'Hauptebene']
    end

    subject { csv }

    its(:headers) { should include(*full_headers) }

    context 'first row' do
      subject { csv[0] }

      its(['Vorname'])      { should eq person.first_name }
      its(['Rollen'])       { should be_blank }
      its(['Anmeldedatum']) { should eq I18n.l(Time.zone.now.to_date) }

      context 'with additional information' do
        before { participation.update_attribute(:additional_information, 'foobar') }
        its(['Bemerkungen']) { should eq 'foobar' }
      end

      context 'with roles' do
        before do
          Fabricate(:event_role, participation: participation, type: 'Event::Role::Leader')
          Fabricate(:event_role, participation: participation, type: 'Event::Role::AssistantLeader')
          participation.reload
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
          expect(subject["#{first_question.question}"]).to eq 'GA'
          expect(subject["#{second_question.question}"]).to eq 'ja'
        end
      end
    end
  end
end
