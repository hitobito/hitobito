#  Copyright (c) 2012-2018, Schweizer Blasmusikverband. This file is part of
#  hitobito_sbv and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require 'spec_helper'

describe Export::Tabular::People::TableDisplays do

  let(:person) { people(:top_leader) }

  context 'people' do
    let(:people_list)   { Export::Tabular::People::TableDisplays.new(list, table_display) }
    let(:table_display) { TableDisplay::People.new }
    let(:list)          { [person] }

    subject { people_list }

    its(:attributes) do
      should == [:first_name, :last_name, :nickname, :company_name, :company, :email, :address,
                 :zip_code, :town, :country, :gender, :birthday, :layer_group, :roles, :tags]
    end

    it 'includes additional attributes if configured' do
      table_display.selected = %w(additional_information)
      expect(people_list.labels.last).to eq 'Zusätzliche Angaben'
      expect(people_list.attributes.last).to eq :additional_information
      expect(people_list.data_rows.first.last).to eq 'bla bla'
    end

    it 'does not include the same attriubte twice' do
      table_display.selected = %w(first_name)
      expect(people_list.attributes.grep(/first_name/).count).to eq 1
    end

    context :with_permission_check do
      before  { TableDisplay.register_permission(Person, :show_full, :additional_information) }
      after   { TableDisplay.class_variable_set('@@permissions', {}) }

      context :as_leader do
        let(:table_display) { TableDisplay::People.new(person: people(:top_leader)) }

        it 'does render value for protected attr' do
          table_display.selected = %w(additional_information)
          expect(people_list.labels.last).to eq 'Zusätzliche Angaben'
          expect(people_list.data_rows.first.last).to eq 'bla bla'
        end
      end

      context :as_member do
        let(:table_display) { TableDisplay::People.new(person: people(:bottom_member)) }

        it 'does not render value for protected attr' do
          table_display.selected = %w(additional_information)
          expect(people_list.labels.last).to eq 'Zusätzliche Angaben'
          expect(people_list.data_rows.first.last).to be_blank
        end
      end
    end
  end

  context 'participations' do
    let(:people_list)   { Export::Tabular::People::TableDisplays.new(list, table_display) }
    let(:table_display) { TableDisplay::Participations.new(person: person) }
    let(:participation) { event_participations(:top) }
    let(:person)        { participation.person }
    let(:list)          { [participation] }
    let(:question)      { event_questions(:top_ov) }
    let(:top_course)    { participation.event }

    subject { people_list }

    its(:attributes) do
      should == [:first_name, :last_name, :nickname, :company_name, :company, :email, :address,
                :zip_code, :town, :country, :gender, :birthday, :layer_group, :roles, :tags]
    end

    it 'includes additional person attributes if configured' do
      table_display.selected = %w(person.additional_information)
      person.update!(additional_information: 'bla bla')
      expect(people_list.labels.last).to eq 'Zusätzliche Angaben'
      expect(people_list.attributes.last).to eq :'person.additional_information'
      expect(people_list.data_rows.first.last).to eq 'bla bla'
    end

    it 'includes configured questions that exist on this event' do
      participation.answers.create!(question: question, answer: 'GA')
      table_display.selected = %W(event_question_1 event_question_#{question.id} event_question_2)
      expect(people_list.labels.last).to eq 'GA oder Halbtax?'
      expect(people_list.attributes.last.to_s).to eq "event_question_#{question.id}"
      expect(people_list.data_rows.first.last).to eq 'GA'
    end

    it 'does not include the same attribute twice' do
      table_display.selected = %W(person.gender)
      expect(people_list.attributes.grep(/gender/).count).to eq 1
    end

    context :with_permission_check do
      before  { TableDisplay.register_permission(Person, :show_full, :additional_information) }
      after   { TableDisplay.class_variable_set('@@permissions', {}) }

      context :event_leader do
        let(:person) { Fabricate(Event::Role::Leader.sti_name, participation: Fabricate(:event_participation, event: top_course)).person  }

        it 'does include value of configured questions' do
          participation.answers.create!(question: question, answer: 'GA')
          table_display.selected = %W(event_question_1 event_question_#{question.id} event_question_2)
          expect(people_list.data_rows.first.last).to eq 'GA'
        end

        it 'does not include value of protected attr' do
          table_display.selected = %w(person.additional_information)
          person.update!(additional_information: 'bla bla')
          expect(people_list.labels.last).to eq 'Zusätzliche Angaben'
          expect(people_list.attributes.last).to eq :'person.additional_information'
          expect(people_list.data_rows.first.last).to be_blank
        end
      end

      context :event_participant do
        let(:person) { Fabricate(Event::Role::Participant.sti_name, participation: Fabricate(:event_participation, event: top_course)).person }

        it 'does not include value of configured questions' do
          participation.answers.create!(question: question, answer: 'GA')
          table_display.selected = %W(event_question_1 event_question_#{question.id} event_question_2)
          expect(people_list.data_rows.first.last).to be_blank
        end
      end
    end
  end
end
